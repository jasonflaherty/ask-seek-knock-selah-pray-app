import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/db/app_database.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/data/drift_prayer_repository.dart';
import 'package:selah/features/prayers/domain/prayer.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftPrayerRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 4, 1, 12));
    repo = DriftPrayerRepository(db, clock);
  });

  tearDown(() async {
    await db.close();
  });

  test('create shared prayer assigns syncId', () async {
    final id = await repo.createPrayer(
      const NewPrayer(
        name: 'Healing',
        request: 'Please pray for recovery',
        shared: true,
        authorEmail: 'a@example.com',
      ),
    );
    final p = await repo.getPrayer(id);
    expect(p!.shared, isTrue);
    expect(p.syncId, isNotNull);
    expect(p.authorEmail, 'a@example.com');
  });

  test('unshare writes tombstone and keeps local prayer', () async {
    final id = await repo.createPrayer(
      const NewPrayer(
        name: 'Healing',
        request: 'Please pray for recovery',
        shared: true,
        authorEmail: 'a@example.com',
      ),
    );
    final before = await repo.getPrayer(id);
    await repo.setShared(id, shared: false);
    final after = await repo.getPrayer(id);
    expect(after!.shared, isFalse);
    expect(after.syncId, before!.syncId);

    final tombs = await db.select(db.syncTombstones).get();
    expect(tombs, hasLength(1));
    expect(tombs.single.syncId, before.syncId);
  });

  test('delete shared prayer writes tombstone', () async {
    final id = await repo.createPrayer(
      const NewPrayer(
        name: 'Healing',
        request: 'Please pray for recovery',
        shared: true,
        authorEmail: 'a@example.com',
      ),
    );
    final p = await repo.getPrayer(id);
    await repo.deletePrayer(id);
    final tombs = await db.select(db.syncTombstones).get();
    expect(tombs.single.syncId, p!.syncId);
    expect(await repo.getPrayer(id), isNull);
  });

  test('purge removes without tombstone', () async {
    final id = await repo.createPrayer(
      const NewPrayer(
        name: 'Healing',
        request: 'Please pray for recovery',
        shared: true,
        authorEmail: 'a@example.com',
      ),
    );
    await repo.purgePrayer(id);
    expect(await db.select(db.syncTombstones).get(), isEmpty);
  });
}
