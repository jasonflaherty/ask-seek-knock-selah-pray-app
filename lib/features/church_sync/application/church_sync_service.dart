import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/clock.dart';
import '../../prayers/domain/prayer.dart';
import '../../prayers/domain/prayer_repository.dart';
import '../../verses/domain/bible_reference.dart';
import '../../verses/domain/custom_verse_repository.dart';
import '../data/sync_snapshot_store.dart';
import '../domain/church_sync_prefs.dart';
import '../domain/sheet_merge.dart';
import '../domain/sheet_row.dart';
import '../domain/sheets_gateway.dart';

class ChurchSyncStatus {
  const ChurchSyncStatus({
    this.email,
    this.spreadsheetId,
    this.lastSyncAt,
  });

  final String? email;
  final String? spreadsheetId;
  final DateTime? lastSyncAt;

  bool get isSignedIn => email != null && email!.isNotEmpty;
  bool get hasSpreadsheet =>
      spreadsheetId != null && spreadsheetId!.isNotEmpty;
  bool get canSync => isSignedIn && hasSpreadsheet;
}

class ChurchSyncResult {
  const ChurchSyncResult({
    required this.pulled,
    required this.pushed,
    required this.removed,
  });

  final int pulled;
  final int pushed;
  final int removed;
}

/// Coordinates Google sign-in, merge, and local apply for church prayers.
class ChurchSyncService {
  ChurchSyncService({
    required PrayerRepository this._prayers,
    required CustomVerseRepository this._customVerses,
    required SyncSnapshotStore this._snapshots,
    required SheetsGateway this._gateway,
    required SharedPreferences this._prefs,
    required Clock this._clock,
  });

  final PrayerRepository _prayers;
  final CustomVerseRepository _customVerses;
  final SyncSnapshotStore _snapshots;
  final SheetsGateway _gateway;
  final SharedPreferences _prefs;
  final Clock _clock;

  ChurchSyncStatus status() {
    final last = _prefs.getString(ChurchSyncPrefs.lastSyncKey);
    return ChurchSyncStatus(
      email: _prefs.getString(ChurchSyncPrefs.emailKey),
      spreadsheetId: _prefs.getString(ChurchSyncPrefs.spreadsheetIdKey),
      lastSyncAt: last == null ? null : DateTime.tryParse(last),
    );
  }

  Future<String> signIn() async {
    final email = await _gateway.signIn();
    await _prefs.setString(ChurchSyncPrefs.emailKey, email);
    return email;
  }

  Future<void> signOut() async {
    await _gateway.signOut();
    await _prefs.remove(ChurchSyncPrefs.emailKey);
  }

  Future<void> linkSpreadsheet(String spreadsheetIdOrUrl) async {
    final id = parseSpreadsheetId(spreadsheetIdOrUrl);
    if (id == null) {
      throw SheetsGatewayException(
        'Paste a Google Sheets link or spreadsheet id.',
      );
    }
    await _prefs.setString(ChurchSyncPrefs.spreadsheetIdKey, id);
  }

  Future<String> createAndLinkSpreadsheet({
    String title = 'Selah Church Prayers',
  }) async {
    final id = await _gateway.createChurchSpreadsheet(title: title);
    await _prefs.setString(ChurchSyncPrefs.spreadsheetIdKey, id);
    return id;
  }

  Future<void> unlinkSpreadsheet() async {
    await _prefs.remove(ChurchSyncPrefs.spreadsheetIdKey);
    await _prefs.remove(ChurchSyncPrefs.lastSyncKey);
  }

  Future<ChurchSyncResult> syncNow() async {
    final current = status();
    if (!current.canSync) {
      throw SheetsGatewayException(
        'Sign in with Google and link a church spreadsheet first.',
      );
    }
    final spreadsheetId = current.spreadsheetId!;
    final email = current.email!;

    final localChurch = await _prayers.churchPrayers();
    // Ensure every church prayer has author email when first shared.
    for (final p in localChurch) {
      if (p.authorEmail.isEmpty && p.syncId != null) {
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
            shared: true,
            authorEmail: email,
            syncId: p.syncId,
          ),
        );
      }
    }
    final refreshedChurch = await _prayers.churchPrayers();

    final remote = await _gateway.readPrayers(spreadsheetId);
    final remoteVerses = await _gateway.readVerses(spreadsheetId);
    final snapshots = await _snapshots.allSnapshots();
    final tombstones = await _snapshots.allTombstones();

    final merge = mergeChurchSheet(
      localChurch: refreshedChurch,
      remote: remote,
      snapshots: snapshots,
      tombstones: tombstones,
    );

    // Apply local deletes first (remote tombstone / merge).
    for (final syncId in merge.localDeletes) {
      final existing = await _prayers.getPrayerBySyncId(syncId);
      if (existing != null) {
        await _prayers.purgePrayer(existing.id);
      }
    }

    // Apply local upserts from sheet.
    for (final row in merge.localUpserts) {
      await _applyRemoteRow(row, email);
      await _ensureCustomVerses(row.verseIds, remoteVerses);
    }

    // Build full sheet state after merge for rewrite.
    final afterLocal = await _prayers.churchPrayers();
    final sheetById = <String, SheetPrayerRow>{
      for (final r in remote)
        if (!r.deleted && !merge.sheetDeletes.contains(r.syncId))
          r.syncId: r,
    };
    for (final id in merge.sheetDeletes) {
      sheetById.remove(id);
    }
    for (final row in merge.sheetUpserts) {
      sheetById[row.syncId] = row;
    }
    // Ensure every local church prayer is represented.
    for (final p in afterLocal) {
      if (p.syncId == null) continue;
      if (merge.localDeletes.contains(p.syncId)) continue;
      sheetById.putIfAbsent(p.syncId!, () => prayerToSheetRow(p));
      // Prefer latest local if we just upserted it.
      if (merge.sheetUpserts.any((r) => r.syncId == p.syncId)) {
        sheetById[p.syncId!] = prayerToSheetRow(p);
      }
    }

    // Append tombstone rows for deletes that need to stay visible once.
    final deletedRows = <SheetPrayerRow>[];
    for (final syncId in merge.sheetDeletes) {
      final prior = remote.cast<SheetPrayerRow?>().firstWhere(
            (r) => r?.syncId == syncId,
            orElse: () => null,
          );
      deletedRows.add(
        SheetPrayerRow(
          syncId: syncId,
          authorEmail: prior?.authorEmail ?? email,
          name: prior?.name ?? '',
          person: prior?.person ?? '',
          request: prior?.request ?? '',
          tags: prior?.tags ?? const [],
          verseIds: prior?.verseIds ?? const [],
          isAnswered: prior?.isAnswered ?? false,
          answeredNote: prior?.answeredNote,
          updatedAt: _clock.now(),
          deleted: true,
        ),
      );
    }

    final activeRows = sheetById.values.toList()
      ..sort((a, b) => a.syncId.compareTo(b.syncId));
    final writeRows = [...activeRows, ...deletedRows];

    await _gateway.writePrayers(spreadsheetId, writeRows);

    // Push custom verses referenced by church prayers.
    final verseIds = <String>{
      for (final p in afterLocal) ...p.verseIds,
      for (final r in merge.localUpserts) ...r.verseIds,
    }.where(isCustomVerseId).toSet();

    final verseRows = <SheetVerseRow>[];
    for (final id in verseIds) {
      final v = await _customVerses.getById(id);
      if (v != null) {
        verseRows.add(
          SheetVerseRow(id: v.id, ref: v.ref, text: v.text, note: v.note),
        );
      }
    }
    // Keep existing remote verses that are still referenced.
    for (final rv in remoteVerses) {
      if (verseIds.contains(rv.id) &&
          !verseRows.any((v) => v.id == rv.id)) {
        verseRows.add(rv);
      }
    }
    if (verseRows.isNotEmpty) {
      await _gateway.writeVerses(spreadsheetId, verseRows);
    }

    await _snapshots.replaceSnapshots(merge.snapshotFingerprints);
    await _snapshots.clearTombstones(merge.sheetDeletes);
    await _prefs.setString(
      ChurchSyncPrefs.lastSyncKey,
      _clock.now().toUtc().toIso8601String(),
    );

    return ChurchSyncResult(
      pulled: merge.localUpserts.length,
      pushed: merge.sheetUpserts.length,
      removed: merge.localDeletes.length + merge.sheetDeletes.length,
    );
  }

  Future<void> _applyRemoteRow(SheetPrayerRow row, String fallbackEmail) async {
    final existing = await _prayers.getPrayerBySyncId(row.syncId);
    final author = row.authorEmail.isNotEmpty
        ? row.authorEmail
        : fallbackEmail;
    if (existing == null) {
      final id = await _prayers.createPrayer(
        NewPrayer(
          name: row.name,
          person: row.person,
          request: row.request,
          tags: row.tags,
          verseIds: row.verseIds,
          shared: true,
          authorEmail: author,
          syncId: row.syncId,
        ),
      );
      if (row.isAnswered) {
        await _prayers.setAnswered(
          id,
          answered: true,
          note: row.answeredNote,
        );
      }
      return;
    }

    await _prayers.updatePrayer(
      existing.id,
      PrayerUpdate(
        name: row.name,
        person: row.person,
        request: row.request,
        tags: row.tags,
        verseIds: row.verseIds,
        isAnswered: row.isAnswered,
        answeredNote: row.answeredNote,
        shared: true,
        authorEmail: author,
        syncId: row.syncId,
      ),
    );
  }

  Future<void> _ensureCustomVerses(
    List<String> verseIds,
    List<SheetVerseRow> remoteVerses,
  ) async {
    final byId = {for (final v in remoteVerses) v.id: v};
    for (final id in verseIds) {
      if (!isCustomVerseId(id)) continue;
      final existing = await _customVerses.getById(id);
      if (existing != null) continue;
      final remote = byId[id];
      if (remote == null) continue;
      // Import with a new local custom id would break references; store by
      // inserting with the remote id via the repository's addCustom would mint
      // a new id. Use a dedicated import path when available.
      await _importCustomVerse(remote);
    }
  }

  Future<void> _importCustomVerse(SheetVerseRow row) async {
    await _customVerses.importCustom(
      id: row.id,
      ref: row.ref,
      text: row.text,
      note: row.note,
    );
  }
}

/// Accepts a full Sheets URL or bare spreadsheet id.
String? parseSpreadsheetId(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final fromUrl = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)').firstMatch(trimmed);
  if (fromUrl != null) return fromUrl.group(1);
  if (RegExp(r'^[a-zA-Z0-9-_]+$').hasMatch(trimmed) && trimmed.length >= 20) {
    return trimmed;
  }
  return null;
}
