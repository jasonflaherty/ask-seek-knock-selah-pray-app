import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/db/app_database.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/data/drift_prayer_repository.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/prayers/domain/prayer_event.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftPrayerRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime(2024, 6, 15, 12));
    repo = DriftPrayerRepository(db, clock);
  });

  tearDown(() async {
    await db.close();
  });

  test('create and get prayer with tags and verses', () async {
    final id = await repo.createPrayer(
      const NewPrayer(
        name: 'Mom',
        request: 'Healing for her back',
        tags: ['family', 'healing'],
        verseIds: ['jam-5-14-15'],
      ),
    );

    final prayer = await repo.getPrayer(id);
    expect(prayer, isNotNull);
    expect(prayer!.name, 'Mom');
    expect(prayer.request, 'Healing for her back');
    expect(prayer.tags, ['family', 'healing']);
    expect(prayer.verseIds, ['jam-5-14-15']);
    expect(prayer.isAnswered, isFalse);
    expect(prayer.timesViewed, 0);
    expect(prayer.lastPrayedAt, isNull);
  });

  test('update prayer replaces tags and verses in one transaction', () async {
    final id = await repo.createPrayer(
      const NewPrayer(name: 'A', request: 'R', tags: ['old'], verseIds: ['v1']),
    );

    await repo.updatePrayer(
      id,
      const PrayerUpdate(
        name: 'B',
        request: 'Updated',
        tags: ['new', 'also'],
        verseIds: ['v2', 'v3'],
      ),
    );

    final prayer = await repo.getPrayer(id);
    expect(prayer!.name, 'B');
    expect(prayer.request, 'Updated');
    expect(prayer.tags, ['new', 'also']);
    expect(prayer.verseIds, ['v2', 'v3']);
  });

  test('delete cascades tags links, verses, and events', () async {
    final id = await repo.createPrayer(
      const NewPrayer(name: 'X', request: 'Y', tags: ['t'], verseIds: ['v']),
    );
    await repo.logEvent(id, PrayerEventType.viewed);
    await repo.deletePrayer(id);

    expect(await repo.getPrayer(id), isNull);
    final events = await db.select(db.prayerEvents).get();
    expect(events, isEmpty);
    final links = await db.select(db.prayerTags).get();
    expect(links, isEmpty);
    final verses = await db.select(db.prayerVerses).get();
    expect(verses, isEmpty);
  });

  test('tag reuse is case-insensitive and preserves first casing', () async {
    final id1 = await repo.createPrayer(
      const NewPrayer(name: 'One', request: 'R', tags: ['Family']),
    );
    final id2 = await repo.createPrayer(
      const NewPrayer(name: 'Two', request: 'R', tags: ['family']),
    );

    final p1 = await repo.getPrayer(id1);
    final p2 = await repo.getPrayer(id2);
    expect(p1!.tags, ['Family']);
    expect(p2!.tags, ['Family']);

    final allTags = await db.select(db.tags).get();
    expect(allTags.length, 1);
    expect(allTags.single.label, 'Family');
  });

  test('setAnswered sets answeredAt via clock and logs event', () async {
    final id = await repo.createPrayer(
      const NewPrayer(name: 'Job', request: 'Provision'),
    );
    clock.set(DateTime(2024, 7, 1, 9));
    await repo.setAnswered(id, answered: true, note: 'New job offer');

    final prayer = await repo.getPrayer(id);
    expect(prayer!.isAnswered, isTrue);
    expect(prayer.answeredAt, DateTime(2024, 7, 1, 9));
    expect(prayer.answeredNote, 'New job offer');

    final events = await db.select(db.prayerEvents).get();
    expect(events.single.type, 'answered');

    await repo.setAnswered(id, answered: false);
    final unanswered = await repo.getPrayer(id);
    expect(unanswered!.isAnswered, isFalse);
    expect(unanswered.answeredAt, isNull);
  });

  test('event logging derives timesViewed and lastPrayedAt', () async {
    final id = await repo.createPrayer(
      const NewPrayer(name: 'Friend', request: 'Peace'),
    );

    clock.set(DateTime(2024, 6, 15, 13));
    await repo.logEvent(id, PrayerEventType.viewed);
    clock.advance(const Duration(minutes: 1));
    await repo.logEvent(id, PrayerEventType.viewed);
    clock.set(DateTime(2024, 6, 16, 8));
    await repo.logEvent(id, PrayerEventType.prayed);

    final prayer = await repo.getPrayer(id);
    expect(prayer!.timesViewed, 2);
    expect(prayer.lastPrayedAt, DateTime(2024, 6, 16, 8));
  });

  test('watchPrayers filters by answer status', () async {
    await repo.createPrayer(const NewPrayer(name: 'Active', request: 'A'));
    final answeredId = await repo.createPrayer(
      const NewPrayer(name: 'Done', request: 'B'),
    );
    await repo.setAnswered(answeredId, answered: true);

    final active = await repo.watchPrayers(filter: AnswerFilter.active).first;
    final answered = await repo.watchPrayers(filter: AnswerFilter.answered).first;
    final all = await repo.watchPrayers(filter: AnswerFilter.all).first;

    expect(active.map((p) => p.name), ['Active']);
    expect(answered.map((p) => p.name), ['Done']);
    expect(all.length, 2);
  });

  test('allTagLabels returns sorted unique labels', () async {
    await repo.createPrayer(
      const NewPrayer(name: 'A', request: 'R', tags: ['zebra', 'apple']),
    );
    await repo.createPrayer(
      const NewPrayer(name: 'B', request: 'R', tags: ['Banana']),
    );
    final labels = await repo.allTagLabels();
    expect(labels, ['apple', 'Banana', 'zebra']);
  });

  test('normalizeTagLabel collapses spaces', () {
    expect(normalizeTagLabel('  family  healing '), 'family healing');
    expect(normalizeTagLabel('   '), '');
  });
}
