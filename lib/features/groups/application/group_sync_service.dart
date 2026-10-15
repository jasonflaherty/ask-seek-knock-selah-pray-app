import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/utils/sync_id.dart';
import '../../prayers/domain/prayer.dart';
import '../../prayers/domain/prayer_repository.dart';
import '../../prayers/domain/share_scope.dart';
import '../../verses/domain/custom_verse_repository.dart';
import '../data/http_selah_api.dart';
import '../domain/group_models.dart';
import '../domain/selah_api.dart';

final selahApiProvider = Provider<SelahApi>((ref) => HttpSelahApi());

final groupSyncServiceProvider = Provider<GroupSyncService>((ref) {
  return GroupSyncService(
    api: ref.watch(selahApiProvider),
    prayers: ref.watch(prayerRepositoryProvider),
    customVerses: ref.watch(customVerseRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
});

class GroupSyncService {
  GroupSyncService({
    required SelahApi api,
    required PrayerRepository prayers,
    required CustomVerseRepository customVerses,
    required AppDatabase db,
  })  : _api = api,
        _prayers = prayers,
        _customVerses = customVerses,
        _db = db;

  final SelahApi _api;
  final PrayerRepository _prayers;
  final CustomVerseRepository _customVerses;
  final AppDatabase _db;

  Future<void> syncNow(AuthSession session) async {
    if (session.membership == null) return;
    final token = session.token;

    final remote = await _api.pullPrayers(token);
    for (final tomb in remote.tombstones) {
      final local = await _prayers.getPrayerBySyncId(tomb.syncId);
      if (local != null) {
        await _prayers.purgePrayer(local.id);
      }
      await (_db.delete(_db.syncTombstones)
            ..where((t) => t.syncId.equals(tomb.syncId)))
          .go();
    }

    for (final rp in remote.prayers) {
      await _applyRemote(rp, session);
    }

    final localTombs = await _db.select(_db.syncTombstones).get();
    for (final tomb in localTombs) {
      try {
        await _api.deletePrayer(token, tomb.syncId);
        await (_db.delete(_db.syncTombstones)
              ..where((t) => t.syncId.equals(tomb.syncId)))
            .go();
      } catch (_) {}
    }

    final shared = await _prayers.sharedPrayers();
    for (final p in shared) {
      if (p.syncId == null) continue;
      // Legacy church rows wait for explicit confirm.
      if (p.shareScope == ShareScope.church &&
          (p.churchId == null || p.churchId!.isEmpty)) {
        continue;
      }
      await _pushLocal(token, p, session);
    }

    await _syncNotes(session);
  }

  Future<void> uploadLocalChurchPrayers(AuthSession session) async {
    final membership = session.membership;
    if (membership == null) return;
    final shared = await _prayers.sharedPrayers();
    for (final p in shared) {
      if (p.shareScope != ShareScope.church) continue;
      await _prayers.updatePrayer(
        p.id,
        PrayerUpdate(
          name: p.name,
          person: p.person,
          request: p.request,
          tags: p.tags,
          verseIds: p.verseIds,
          isAnswered: p.isAnswered,
          answeredNote: p.answeredNote,
          shareScope: ShareScope.church,
          churchId: membership.churchId,
          groupId: membership.groupId,
          authorEmail: session.user.email,
          authorDisplayName: session.user.displayName,
          syncId: p.syncId ?? newSyncId(),
        ),
      );
      final updated = await _prayers.getPrayer(p.id);
      if (updated != null) {
        await _pushLocal(session.token, updated, session);
      }
    }
    await syncNow(session);
  }

  Future<void> _applyRemote(
    RemoteSharedPrayer rp,
    AuthSession session,
  ) async {
    for (final cv in rp.customVerses) {
      final id = cv['id'] as String?;
      final ref = cv['ref'] as String?;
      final body = cv['body'] as String?;
      if (id == null || ref == null || body == null) continue;
      final existing = await _customVerses.getById(id);
      if (existing == null) {
        await _customVerses.importCustom(
          id: id,
          ref: ref,
          text: body,
          note: cv['note'] as String?,
        );
      }
    }

    final scope = ShareScopeX.fromStorage(rp.shareScope);
    final local = await _prayers.getPrayerBySyncId(rp.syncId);
    if (local == null) {
      await _prayers.createPrayer(
        NewPrayer(
          name: rp.name,
          person: rp.person,
          request: rp.request,
          tags: rp.tags,
          verseIds: rp.verseIds,
          shareScope: scope,
          groupId: rp.groupId,
          churchId: rp.churchId,
          authorEmail: '',
          authorDisplayName: rp.authorDisplayName,
          syncId: rp.syncId,
        ),
      );
      final created = await _prayers.getPrayerBySyncId(rp.syncId);
      if (created != null && rp.isAnswered) {
        await _prayers.setAnswered(
          created.id,
          answered: true,
          note: rp.answeredNote,
        );
      }
      return;
    }

    if (local.updatedAt.isAfter(rp.updatedAt)) {
      return;
    }

    await _prayers.updatePrayer(
      local.id,
      PrayerUpdate(
        name: rp.name,
        person: rp.person,
        request: rp.request,
        tags: rp.tags,
        verseIds: rp.verseIds,
        isAnswered: rp.isAnswered,
        answeredNote: rp.answeredNote,
        shareScope: scope,
        groupId: rp.groupId,
        churchId: rp.churchId,
        authorDisplayName: rp.authorDisplayName,
        syncId: rp.syncId,
      ),
    );
  }

  Future<void> _pushLocal(
    String token,
    Prayer p,
    AuthSession session,
  ) async {
    final membership = session.membership!;
    final syncId = p.syncId ?? newSyncId();
    final custom = <Map<String, dynamic>>[];
    for (final vid in p.verseIds) {
      if (!vid.startsWith('custom:')) continue;
      final cv = await _customVerses.getById(vid);
      if (cv == null) continue;
      custom.add({
        'id': cv.id,
        'ref': cv.ref,
        'body': cv.text,
        'note': cv.note,
      });
    }

    await _api.pushPrayer(token, {
      'syncId': syncId,
      'shareScope': p.shareScope == ShareScope.group ? 'group' : 'church',
      'name': p.name,
      'person': p.person,
      'request': p.request,
      'isAnswered': p.isAnswered,
      'answeredAt': p.answeredAt?.toIso8601String(),
      'answeredNote': p.answeredNote,
      'tags': p.tags,
      'verseIds': p.verseIds,
      'customVerses': custom,
      'updatedAt': p.updatedAt.toIso8601String(),
      'createdAt': p.createdAt.toIso8601String(),
      'churchId': p.churchId ?? membership.churchId,
      'groupId': p.shareScope == ShareScope.group
          ? (p.groupId ?? membership.groupId)
          : null,
    });

    if (p.syncId == null ||
        p.churchId == null ||
        (p.shareScope == ShareScope.group && p.groupId == null)) {
      await _prayers.updatePrayer(
        p.id,
        PrayerUpdate(
          name: p.name,
          person: p.person,
          request: p.request,
          tags: p.tags,
          verseIds: p.verseIds,
          isAnswered: p.isAnswered,
          answeredNote: p.answeredNote,
          shareScope: p.shareScope,
          syncId: syncId,
          churchId: membership.churchId,
          groupId: p.shareScope == ShareScope.group
              ? membership.groupId
              : p.groupId,
          authorEmail: session.user.email,
          authorDisplayName: session.user.displayName,
        ),
      );
    }
  }

  Future<void> _syncNotes(AuthSession session) async {
    final membership = session.membership;
    if (membership == null) return;
    final notes = await _api.listNotes(session.token);
    await (_db.delete(_db.studyNotes)
          ..where((t) => t.groupId.equals(membership.groupId)))
        .go();
    for (final n in notes) {
      await _db.into(_db.studyNotes).insertOnConflictUpdate(
            StudyNotesCompanion.insert(
              id: n.id,
              groupId: membership.groupId,
              authorUserId: n.authorUserId,
              authorDisplayName: Value(n.authorDisplayName),
              kind: n.kind,
              body: n.body,
              createdAt: n.createdAt,
              updatedAt: n.updatedAt,
            ),
          );
    }
  }
}
