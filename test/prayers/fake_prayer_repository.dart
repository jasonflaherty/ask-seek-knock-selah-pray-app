import 'dart:async';

import 'package:selah/core/utils/clock.dart';
import 'package:selah/core/utils/sync_id.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/prayers/domain/prayer_event.dart';
import 'package:selah/features/prayers/domain/prayer_repository.dart';
import 'package:selah/features/prayers/domain/share_scope.dart';

class FakePrayerRepository implements PrayerRepository {
  FakePrayerRepository([Clock? clock]) : _clock = clock ?? const SystemClock();

  final Clock _clock;
  final _controller = StreamController<List<Prayer>>.broadcast();
  final Map<int, Prayer> _prayers = {};
  final Map<int, List<PrayerEventType>> _events = {};
  final Map<String, DateTime> tombstones = {};
  int _nextId = 1;

  void dispose() {
    _controller.close();
  }

  List<Prayer> get allPrayers => _prayers.values.toList();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_prayers.values.toList());
    }
  }

  List<Prayer> _filtered(AnswerFilter filter) {
    final all = _prayers.values.toList();
    return switch (filter) {
      AnswerFilter.active => all.where((p) => !p.isAnswered).toList(),
      AnswerFilter.answered => all.where((p) => p.isAnswered).toList(),
      AnswerFilter.all => all,
    };
  }

  @override
  Stream<List<Prayer>> watchPrayers({required AnswerFilter filter}) {
    late final StreamController<List<Prayer>> out;
    StreamSubscription<List<Prayer>>? sub;
    out = StreamController<List<Prayer>>(
      sync: true,
      onListen: () {
        out.add(_filtered(filter));
        sub = _controller.stream.listen((_) => out.add(_filtered(filter)));
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<Prayer?> getPrayer(int id) async => _prayers[id];

  @override
  Future<Prayer?> getPrayerBySyncId(String syncId) async {
    for (final p in _prayers.values) {
      if (p.syncId == syncId) return p;
    }
    return null;
  }

  @override
  Future<int> createPrayer(NewPrayer input) async {
    final id = _nextId++;
    final now = _clock.now();
    final scope = input.shareScope;
    _prayers[id] = Prayer(
      id: id,
      name: input.name.trim(),
      person: normalizePerson(input.person),
      request: input.request.trim(),
      isAnswered: false,
      createdAt: now,
      updatedAt: now,
      tags: List.of(input.tags),
      verseIds: List.of(input.verseIds),
      syncId: scope.isShared ? (input.syncId ?? newSyncId()) : input.syncId,
      shareScope: scope,
      groupId: input.groupId,
      churchId: input.churchId,
      authorEmail: scope.isShared ? input.authorEmail.trim().toLowerCase() : '',
      authorDisplayName: scope.isShared ? input.authorDisplayName.trim() : '',
    );
    _emit();
    return id;
  }

  @override
  Future<void> updatePrayer(int id, PrayerUpdate input) async {
    final existing = _prayers[id];
    if (existing == null) return;
    final now = _clock.now();
    var isAnswered = existing.isAnswered;
    DateTime? answeredAt = existing.answeredAt;
    String? answeredNote = existing.answeredNote;
    if (input.isAnswered != null) {
      isAnswered = input.isAnswered!;
      if (isAnswered) {
        answeredAt ??= now;
        answeredNote = input.answeredNote ?? answeredNote;
      } else {
        answeredAt = null;
        answeredNote = null;
      }
    }

    var scope = existing.shareScope;
    var syncId = existing.syncId;
    var authorEmail = existing.authorEmail;
    var authorDisplayName = existing.authorDisplayName;
    var groupId = existing.groupId;
    var churchId = existing.churchId;
    if (input.shareScope != null) {
      final next = input.shareScope!;
      if (next.isShared && !existing.shareScope.isShared) {
        scope = next;
        syncId ??= input.syncId ?? newSyncId();
        final email = (input.authorEmail ?? existing.authorEmail).trim();
        if (email.isNotEmpty) authorEmail = email.toLowerCase();
        final display =
            (input.authorDisplayName ?? existing.authorDisplayName).trim();
        if (display.isNotEmpty) authorDisplayName = display;
        groupId = input.groupId ?? groupId;
        churchId = input.churchId ?? churchId;
        tombstones.remove(syncId);
      } else if (!next.isShared && existing.shareScope.isShared) {
        scope = ShareScope.justMe;
        if (existing.syncId != null) {
          tombstones[existing.syncId!] = now;
        }
        authorEmail = '';
        authorDisplayName = '';
        groupId = null;
        churchId = null;
      } else {
        scope = next;
        groupId = input.groupId ?? groupId;
        churchId = input.churchId ?? churchId;
      }
    }
    if (input.syncId != null) syncId = input.syncId;
    if (input.authorEmail != null && scope.isShared) {
      authorEmail = input.authorEmail!.trim().toLowerCase();
    }
    if (input.authorDisplayName != null && scope.isShared) {
      authorDisplayName = input.authorDisplayName!.trim();
    }

    _prayers[id] = existing.copyWith(
      name: input.name.trim(),
      person: normalizePerson(input.person),
      request: input.request.trim(),
      tags: List.of(input.tags),
      verseIds: List.of(input.verseIds),
      isAnswered: isAnswered,
      answeredAt: answeredAt,
      answeredNote: answeredNote,
      updatedAt: now,
      syncId: syncId,
      shareScope: scope,
      groupId: groupId,
      churchId: churchId,
      authorEmail: authorEmail,
      authorDisplayName: authorDisplayName,
      clearAnsweredAt: !isAnswered,
      clearAnsweredNote: !isAnswered,
      clearGroupId: groupId == null,
      clearChurchId: churchId == null,
    );
    _emit();
  }

  @override
  Future<void> deletePrayer(int id) async {
    final existing = _prayers[id];
    if (existing != null && existing.shared && existing.syncId != null) {
      tombstones[existing.syncId!] = _clock.now();
    }
    _prayers.remove(id);
    _events.remove(id);
    _emit();
  }

  @override
  Future<void> purgePrayer(int id) async {
    _prayers.remove(id);
    _events.remove(id);
    _emit();
  }

  @override
  Future<void> setAnswered(int id, {required bool answered, String? note}) async {
    final existing = _prayers[id];
    if (existing == null) return;
    final now = _clock.now();
    _prayers[id] = existing.copyWith(
      isAnswered: answered,
      answeredAt: answered ? now : null,
      answeredNote: answered ? note : null,
      updatedAt: now,
      clearAnsweredAt: !answered,
      clearAnsweredNote: !answered,
    );
    await logEvent(
      id,
      answered ? PrayerEventType.answered : PrayerEventType.unanswered,
    );
    _emit();
  }

  @override
  Future<void> logEvent(int prayerId, PrayerEventType type) async {
    _events.putIfAbsent(prayerId, () => []).add(type);
    final existing = _prayers[prayerId];
    if (existing == null) return;
    final viewed =
        _events[prayerId]!.where((e) => e == PrayerEventType.viewed).length;
    final lastPrayed = _events[prayerId]!.contains(PrayerEventType.prayed)
        ? _clock.now()
        : existing.lastPrayedAt;
    _prayers[prayerId] = existing.copyWith(
      timesViewed: viewed,
      lastPrayedAt: lastPrayed,
    );
    _emit();
  }

  @override
  Future<List<String>> allTagLabels() async {
    final labels = <String>{};
    for (final p in _prayers.values) {
      labels.addAll(p.tags);
    }
    final list = labels.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  @override
  Future<List<String>> allPersonNames() async {
    final names = <String>{};
    for (final p in _prayers.values) {
      if (p.hasPerson) names.add(p.person);
    }
    final list = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  @override
  Future<List<Prayer>> sharedPrayers() async =>
      _prayers.values.where((p) => p.shared).toList();

  @override
  Future<void> setShareScope(
    int id, {
    required ShareScope shareScope,
    String? authorEmail,
    String? authorDisplayName,
    String? groupId,
    String? churchId,
  }) async {
    final existing = _prayers[id];
    if (existing == null) return;
    await updatePrayer(
      id,
      PrayerUpdate(
        name: existing.name,
        person: existing.person,
        request: existing.request,
        tags: existing.tags,
        verseIds: existing.verseIds,
        isAnswered: existing.isAnswered,
        answeredNote: existing.answeredNote,
        shareScope: shareScope,
        authorEmail: authorEmail,
        authorDisplayName: authorDisplayName,
        groupId: groupId,
        churchId: churchId,
      ),
    );
  }
}
