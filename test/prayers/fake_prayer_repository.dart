import 'dart:async';

import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/prayers/domain/prayer_event.dart';
import 'package:selah/features/prayers/domain/prayer_repository.dart';

class FakePrayerRepository implements PrayerRepository {
  FakePrayerRepository([Clock? clock]) : _clock = clock ?? const SystemClock();

  final Clock _clock;
  final _controller = StreamController<List<Prayer>>.broadcast();
  final Map<int, Prayer> _prayers = {};
  final Map<int, List<PrayerEventType>> _events = {};
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
  Future<int> createPrayer(NewPrayer input) async {
    final id = _nextId++;
    final now = _clock.now();
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
      clearAnsweredAt: !isAnswered,
      clearAnsweredNote: !isAnswered,
    );
    _emit();
  }

  @override
  Future<void> deletePrayer(int id) async {
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
    final viewed = _events[prayerId]!.where((e) => e == PrayerEventType.viewed).length;
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
}
