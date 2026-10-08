import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/clock.dart';
import '../domain/prayer.dart';
import '../domain/prayer_event.dart';
import '../domain/prayer_repository.dart';

class DriftPrayerRepository implements PrayerRepository {
  DriftPrayerRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<Prayer>> watchPrayers({required AnswerFilter filter}) {
    final query = _db.select(_db.prayers);
    switch (filter) {
      case AnswerFilter.active:
        query.where((t) => t.isAnswered.equals(false));
      case AnswerFilter.answered:
        query.where((t) => t.isAnswered.equals(true));
      case AnswerFilter.all:
        break;
    }
    return query.watch().asyncMap((rows) async {
      final prayers = <Prayer>[];
      for (final row in rows) {
        prayers.add(await _mapPrayer(row));
      }
      return prayers;
    });
  }

  @override
  Future<Prayer?> getPrayer(int id) async {
    final row = await (_db.select(_db.prayers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapPrayer(row);
  }

  @override
  Future<int> createPrayer(NewPrayer input) async {
    final now = _clock.now();
    return _db.transaction(() async {
      final id = await _db.into(_db.prayers).insert(
            PrayersCompanion.insert(
              name: input.name.trim(),
              request: input.request.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _replaceTags(id, input.tags);
      await _replaceVerses(id, input.verseIds, now);
      return id;
    });
  }

  @override
  Future<void> updatePrayer(int id, PrayerUpdate input) async {
    final now = _clock.now();
    await _db.transaction(() async {
      final existing = await (_db.select(_db.prayers)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing == null) return;

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
      } else if (input.answeredNote != null) {
        answeredNote = input.answeredNote;
      }

      await (_db.update(_db.prayers)..where((t) => t.id.equals(id))).write(
        PrayersCompanion(
          name: Value(input.name.trim()),
          request: Value(input.request.trim()),
          isAnswered: Value(isAnswered),
          answeredAt: Value(answeredAt),
          answeredNote: Value(answeredNote),
          updatedAt: Value(now),
        ),
      );
      await _replaceTags(id, input.tags);
      await _replaceVerses(id, input.verseIds, now);
    });
  }

  @override
  Future<void> deletePrayer(int id) async {
    await (_db.delete(_db.prayers)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setAnswered(int id, {required bool answered, String? note}) async {
    final now = _clock.now();
    await (_db.update(_db.prayers)..where((t) => t.id.equals(id))).write(
      PrayersCompanion(
        isAnswered: Value(answered),
        answeredAt: Value(answered ? now : null),
        answeredNote: Value(answered ? note : null),
        updatedAt: Value(now),
      ),
    );
    await logEvent(
      id,
      answered ? PrayerEventType.answered : PrayerEventType.unanswered,
    );
  }

  @override
  Future<void> logEvent(int prayerId, PrayerEventType type) async {
    await _db.into(_db.prayerEvents).insert(
          PrayerEventsCompanion.insert(
            prayerId: prayerId,
            type: type.storageValue,
            at: _clock.now(),
          ),
        );
  }

  @override
  Future<List<String>> allTagLabels() async {
    final rows = await _db.select(_db.tags).get();
    final labels = rows.map((r) => r.label).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return labels;
  }

  Future<Prayer> _mapPrayer(PrayerRow row) async {
    final tags = await _tagsFor(row.id);
    final verseIds = await _verseIdsFor(row.id);
    final timesViewed = await _countEvents(row.id, PrayerEventType.viewed);
    final lastPrayedAt = await _lastEventAt(row.id, PrayerEventType.prayed);

    return Prayer(
      id: row.id,
      name: row.name,
      request: row.request,
      isAnswered: row.isAnswered,
      answeredAt: row.answeredAt,
      answeredNote: row.answeredNote,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      tags: tags,
      verseIds: verseIds,
      timesViewed: timesViewed,
      lastPrayedAt: lastPrayedAt,
    );
  }

  Future<List<String>> _tagsFor(int prayerId) async {
    final query = _db.select(_db.prayerTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.prayerTags.tagId)),
    ])
      ..where(_db.prayerTags.prayerId.equals(prayerId))
      ..orderBy([OrderingTerm.asc(_db.prayerTags.position)]);

    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.tags).label).toList();
  }

  Future<List<String>> _verseIdsFor(int prayerId) async {
    final rows = await (_db.select(_db.prayerVerses)
          ..where((t) => t.prayerId.equals(prayerId))
          ..orderBy([(t) => OrderingTerm.asc(t.selectedAt)]))
        .get();
    return rows.map((r) => r.verseId).toList();
  }

  Future<int> _countEvents(int prayerId, PrayerEventType type) async {
    final countExp = _db.prayerEvents.id.count();
    final query = _db.selectOnly(_db.prayerEvents)
      ..addColumns([countExp])
      ..where(
        _db.prayerEvents.prayerId.equals(prayerId) &
            _db.prayerEvents.type.equals(type.storageValue),
      );
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<DateTime?> _lastEventAt(int prayerId, PrayerEventType type) async {
    final row = await (_db.select(_db.prayerEvents)
          ..where(
            (t) =>
                t.prayerId.equals(prayerId) &
                t.type.equals(type.storageValue),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.at)])
          ..limit(1))
        .getSingleOrNull();
    return row?.at;
  }

  Future<void> _replaceTags(int prayerId, List<String> labels) async {
    await (_db.delete(_db.prayerTags)..where((t) => t.prayerId.equals(prayerId)))
        .go();

    final seen = <String>{};
    var position = 0;
    for (final raw in labels) {
      final normalized = normalizeTagLabel(raw);
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);

      final tagId = await _getOrCreateTag(normalized);
      await _db.into(_db.prayerTags).insert(
            PrayerTagsCompanion.insert(
              prayerId: prayerId,
              tagId: tagId,
              position: Value(position),
            ),
          );
      position++;
    }
  }

  Future<void> _replaceVerses(
    int prayerId,
    List<String> verseIds,
    DateTime selectedAt,
  ) async {
    await (_db.delete(_db.prayerVerses)..where((t) => t.prayerId.equals(prayerId)))
        .go();
    final seen = <String>{};
    for (final verseId in verseIds) {
      if (verseId.isEmpty || seen.contains(verseId)) continue;
      seen.add(verseId);
      await _db.into(_db.prayerVerses).insert(
            PrayerVersesCompanion.insert(
              prayerId: prayerId,
              verseId: verseId,
              selectedAt: selectedAt,
            ),
          );
    }
  }

  Future<int> _getOrCreateTag(String label) async {
    final existing = await (_db.select(_db.tags)
          ..where((t) => t.label.lower().equals(label.toLowerCase())))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.tags).insert(TagsCompanion.insert(label: label));
  }
}

/// Trim, collapse spaces; empty string if blank after normalize.
String normalizeTagLabel(String raw) {
  return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
}
