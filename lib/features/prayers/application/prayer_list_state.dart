import '../domain/prayer.dart';
import '../domain/sort_mode.dart';

class PrayerListState {
  const PrayerListState({
    this.prayers = const [],
    this.filter = AnswerFilter.active,
    this.personFilter = PersonFilter.all,
    this.sortMode = SortMode.shuffle,
    this.reshuffleCount = 0,
    this.seedDay,
    this.isLoading = true,
    this.knownPersons = const [],
  });

  final List<Prayer> prayers;
  final AnswerFilter filter;
  final PersonFilter personFilter;
  final SortMode sortMode;
  final int reshuffleCount;
  final DateTime? seedDay;
  final bool isLoading;
  final List<String> knownPersons;

  PrayerListState copyWith({
    List<Prayer>? prayers,
    AnswerFilter? filter,
    PersonFilter? personFilter,
    SortMode? sortMode,
    int? reshuffleCount,
    DateTime? seedDay,
    bool? isLoading,
    List<String>? knownPersons,
  }) {
    return PrayerListState(
      prayers: prayers ?? this.prayers,
      filter: filter ?? this.filter,
      personFilter: personFilter ?? this.personFilter,
      sortMode: sortMode ?? this.sortMode,
      reshuffleCount: reshuffleCount ?? this.reshuffleCount,
      seedDay: seedDay ?? this.seedDay,
      isLoading: isLoading ?? this.isLoading,
      knownPersons: knownPersons ?? this.knownPersons,
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
