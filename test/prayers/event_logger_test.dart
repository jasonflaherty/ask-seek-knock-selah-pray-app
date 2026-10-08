import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/analytics/application/event_logger.dart';
import 'package:selah/features/prayers/domain/prayer.dart';

import 'fake_prayer_repository.dart';

void main() {
  test('logs viewed after 2s at 60% visibility', () async {
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    final repo = FakePrayerRepository(clock);
    final logger = EventLogger(repo, clock);
    addTearDown(repo.dispose);

    final id = await repo.createPrayer(
      const NewPrayer(name: 'A', request: 'Request text here'),
    );

    await logger.onVisibilityChanged(id, 0.7);
    clock.advance(const Duration(seconds: 1));
    await logger.onVisibilityChanged(id, 0.7);
    expect(repo.allPrayers.single.timesViewed, 0);

    clock.advance(const Duration(seconds: 1));
    await logger.onVisibilityChanged(id, 0.7);
    expect(repo.allPrayers.single.timesViewed, 1);
  });

  test('debounces viewed for 10 minutes', () async {
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    final repo = FakePrayerRepository(clock);
    final logger = EventLogger(repo, clock);
    addTearDown(repo.dispose);

    final id = await repo.createPrayer(
      const NewPrayer(name: 'A', request: 'Request text here'),
    );

    await logger.onVisibilityChanged(id, 0.8);
    clock.advance(const Duration(seconds: 2));
    await logger.onVisibilityChanged(id, 0.8);
    expect(repo.allPrayers.single.timesViewed, 1);

    await logger.onVisibilityChanged(id, 0.0);
    clock.advance(const Duration(minutes: 5));
    await logger.onVisibilityChanged(id, 0.8);
    clock.advance(const Duration(seconds: 2));
    await logger.onVisibilityChanged(id, 0.8);
    expect(repo.allPrayers.single.timesViewed, 1);

    clock.advance(const Duration(minutes: 6));
    await logger.onVisibilityChanged(id, 0.0);
    await logger.onVisibilityChanged(id, 0.8);
    clock.advance(const Duration(seconds: 2));
    await logger.onVisibilityChanged(id, 0.8);
    expect(repo.allPrayers.single.timesViewed, 2);
  });

  test('prayed logs event', () async {
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    final repo = FakePrayerRepository(clock);
    final logger = EventLogger(repo, clock);
    addTearDown(repo.dispose);

    final id = await repo.createPrayer(
      const NewPrayer(name: 'A', request: 'Request text here'),
    );
    await logger.prayed(id);
    expect(repo.allPrayers.single.lastPrayedAt, isNotNull);
  });
}
