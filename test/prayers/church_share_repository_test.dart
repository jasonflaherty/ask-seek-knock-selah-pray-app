import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/db/app_database.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/data/drift_prayer_repository.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/prayers/domain/share_scope.dart';

void main() {
  late AppDatabase db;
  late DriftPrayerRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = DriftPrayerRepository(db, const SystemClock());
  });

  tearDown(() async {
    await db.close();
  });

  test('Just me prayers are not in sharedPrayers', () async {
    await repo.createPrayer(
      const NewPrayer(name: 'Private', request: 'Keep local'),
    );
    expect(await repo.sharedPrayers(), isEmpty);
  });

  test('Church scope appears in sharedPrayers and gets a sync id', () async {
    final id = await repo.createPrayer(
      const NewPrayer(
        name: 'Elders',
        request: 'Wisdom',
        shareScope: ShareScope.church,
        churchId: 'church-1',
        authorEmail: 'a@example.com',
      ),
    );
    final prayer = await repo.getPrayer(id);
    expect(prayer!.shareScope, ShareScope.church);
    expect(prayer.syncId, isNotNull);
    expect(await repo.sharedPrayers(), hasLength(1));
  });

  test('Clearing share writes a tombstone', () async {
    final id = await repo.createPrayer(
      const NewPrayer(
        name: 'Shared',
        request: 'Help',
        shareScope: ShareScope.group,
        groupId: 'g1',
        churchId: 'c1',
      ),
    );
    final before = await repo.getPrayer(id);
    await repo.setShareScope(id, shareScope: ShareScope.justMe);
    final after = await repo.getPrayer(id);
    expect(after!.shareScope, ShareScope.justMe);
    expect(after.shared, isFalse);
    final tombs = await db.select(db.syncTombstones).get();
    expect(tombs.map((t) => t.syncId), contains(before!.syncId));
  });

  test('Editor scopes: group and church stay distinct', () async {
    await repo.createPrayer(
      const NewPrayer(
        name: 'Group',
        request: 'g',
        shareScope: ShareScope.group,
        groupId: 'g1',
        churchId: 'c1',
      ),
    );
    await repo.createPrayer(
      const NewPrayer(
        name: 'Church',
        request: 'c',
        shareScope: ShareScope.church,
        churchId: 'c1',
      ),
    );
    final shared = await repo.sharedPrayers();
    expect(shared.where((p) => p.isGroup), hasLength(1));
    expect(shared.where((p) => p.isChurch), hasLength(1));
  });
}
