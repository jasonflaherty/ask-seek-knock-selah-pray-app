import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/prayer.dart';

class PrayerCounts {
  const PrayerCounts({required this.active, required this.answered});

  final int active;
  final int answered;

  int get total => active + answered;
}

final prayerCountsProvider = StreamProvider<PrayerCounts>((ref) {
  return ref.watch(prayerRepositoryProvider).watchPrayers(filter: AnswerFilter.all).map(
        (list) => PrayerCounts(
          active: list.where((p) => !p.isAnswered).length,
          answered: list.where((p) => p.isAnswered).length,
        ),
      );
});
