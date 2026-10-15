import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../prayers/domain/prayer.dart';
import '../data/drift_usage_repository.dart';
import '../domain/journal_metrics.dart';
import '../domain/usage_repository.dart';
import 'usage_tracker.dart';

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return DriftUsageRepository(ref.watch(databaseProvider));
});

final usageTrackerProvider = Provider<UsageTracker>((ref) {
  final tracker = UsageTracker(
    ref.watch(usageRepositoryProvider),
    ref.watch(clockProvider),
  );
  ref.onDispose(tracker.dispose);
  return tracker;
});

final prayerMetricsProvider = StreamProvider.autoDispose<PrayerMetrics>((ref) {
  final clock = ref.watch(clockProvider);
  return ref
      .watch(prayerRepositoryProvider)
      .watchPrayers(filter: AnswerFilter.all)
      .map((prayers) {
        return PrayerMetrics(
          active: prayers.where((prayer) => !prayer.isAnswered).length,
          answered: prayers.where((prayer) => prayer.isAnswered).length,
          weeks: prayerStatusByWeek(prayers, now: clock.now()),
          tags: tagTotals(prayers),
        );
      });
});

final usageSessionsProvider = StreamProvider.autoDispose<List<AppSession>>((
  ref,
) {
  return ref.watch(usageRepositoryProvider).watchSessions();
});
