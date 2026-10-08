import '../domain/prayer.dart';
import '../domain/sort_mode.dart';

class PrayerListState {
  const PrayerListState({
    this.prayers = const [],
    this.filter = AnswerFilter.active,
    this.sortMode = SortMode.shuffle,
    this.reshuffleCount = 0,
    this.seedDay,
    this.isLoading = true,
  });

  final List<Prayer> prayers;
  final AnswerFilter filter;
  final SortMode sortMode;
  final int reshuffleCount;
  final DateTime? seedDay;
  final bool isLoading;

  PrayerListState copyWith({
    List<Prayer>? prayers,
    AnswerFilter? filter,
    SortMode? sortMode,
    int? reshuffleCount,
    DateTime? seedDay,
    bool? isLoading,
  }) {
    return PrayerListState(
      prayers: prayers ?? this.prayers,
      filter: filter ?? this.filter,
      sortMode: sortMode ?? this.sortMode,
      reshuffleCount: reshuffleCount ?? this.reshuffleCount,
      seedDay: seedDay ?? this.seedDay,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// A list item that may be a section header (tag sort) or a prayer card.
sealed class PrayerListItem {
  const PrayerListItem();
}

class PrayerSectionHeader extends PrayerListItem {
  const PrayerSectionHeader(this.title);
  final String title;
}

class PrayerListEntry extends PrayerListItem {
  const PrayerListEntry(this.prayer);
  final Prayer prayer;
}
