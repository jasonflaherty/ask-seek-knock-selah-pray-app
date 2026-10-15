import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/metrics/application/usage_tracker.dart';

import 'fake_usage_repository.dart';

void main() {
  test('foreground session records open time until background', () async {
    final repo = FakeUsageRepository();
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    final tracker = UsageTracker(repo, clock);
    addTearDown(() {
      tracker.dispose();
      repo.dispose();
    });

    await tracker.onResumed();
    await tracker.onResumed();
    expect(repo.sessions, hasLength(1));
    expect(tracker.openSessionId, 1);

    clock.advance(const Duration(minutes: 4));
    await tracker.onBackgrounded();
    expect(tracker.openSessionId, isNull);
    expect(repo.sessions.single.duration, const Duration(minutes: 4));

    clock.advance(const Duration(hours: 1));
    await tracker.onResumed();
    expect(repo.sessions, hasLength(2));
    await tracker.onBackgrounded();
  });
}
