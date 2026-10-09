import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/seeded_shuffle.dart';
import '../domain/prayer.dart';
import '../domain/prayer_repository.dart';
import '../domain/sort_mode.dart';
import 'prayer_list_state.dart';

final prayerListProvider =
    StateNotifierProvider<PrayerListNotifier, PrayerListState>((ref) {
  return PrayerListNotifier(
    ref.watch(prayerRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
    ref.watch(clockProvider),
  );
});

class PrayerListNotifier extends StateNotifier<PrayerListState> {
  PrayerListNotifier(this._repo, this._prefs, this._clock)
      : super(PrayerListState(
          sortMode: SortModeX.fromStorage(_prefs.getString(_sortKey)),
          seedDay: _dateOnly(_clock.now()),
        )) {
    _subscribe();
  }

  static const _sortKey = 'sort_mode';

  final PrayerRepository _repo;
  final SharedPreferences _prefs;
  final Clock _clock;
  StreamSubscription<List<Prayer>>? _sub;
  List<Prayer> _raw = const [];

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo.watchPrayers(filter: state.filter).listen((prayers) async {
      _raw = prayers;
      final persons = await _repo.allPersonNames();
      if (!mounted) return;
      _recompute(knownPersons: persons);
    });
  }

  Future<void> setFilter(AnswerFilter filter) async {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter, isLoading: true);
    _subscribe();
  }

  void setPersonFilter(PersonFilter filter) {
    if (filter == state.personFilter) return;
    state = state.copyWith(personFilter: filter);
    _recompute();
  }

  Future<void> setSortMode(SortMode mode) async {
    if (mode == SortMode.shuffle && state.sortMode == SortMode.shuffle) {
      reshuffle();
      return;
    }
    state = state.copyWith(sortMode: mode);
    await _prefs.setString(_sortKey, mode.storageKey);
    _recompute();
  }

  void reshuffle() {
    final today = _dateOnly(_clock.now());
    var count = state.reshuffleCount;
    var day = state.seedDay ?? today;
    if (day != today) {
      day = today;
      count = 0;
    } else {
      count += 1;
    }
    state = state.copyWith(
      sortMode: SortMode.shuffle,
      reshuffleCount: count,
      seedDay: day,
    );
    _prefs.setString(_sortKey, SortMode.shuffle.storageKey);
    _recompute();
  }

  List<PrayerListItem> get displayItems {
    if (state.sortMode == SortMode.tag) {
      return _tagGroupedItems(state.prayers);
    }
    return state.prayers.map(PrayerListEntry.new).toList();
  }

  void _recompute({List<String>? knownPersons}) {
    final today = _dateOnly(_clock.now());
    var reshuffleCount = state.reshuffleCount;
    var seedDay = state.seedDay ?? today;
    if (seedDay != today) {
      seedDay = today;
      reshuffleCount = 0;
    }

    final personFiltered =
        _raw.where(state.personFilter.matches).toList(growable: false);

    final sorted = sortPrayers(
      personFiltered,
      mode: state.sortMode,
      seed: dailyShuffleSeed(seedDay, reshuffleCount),
    );

    state = state.copyWith(
      prayers: sorted,
      reshuffleCount: reshuffleCount,
      seedDay: seedDay,
      isLoading: false,
      knownPersons: knownPersons,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Pure sort used by the notifier and unit tests.
List<Prayer> sortPrayers(
  List<Prayer> input, {
  required SortMode mode,
  required int seed,
}) {
  final list = List<Prayer>.from(input);
  switch (mode) {
    case SortMode.shuffle:
      list.sort((a, b) {
        final ka = shuffleOrderKey(seed, a.id);
        final kb = shuffleOrderKey(seed, b.id);
        final cmp = ka.compareTo(kb);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });
    case SortMode.newest:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case SortMode.oldest:
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case SortMode.name:
      list.sort((a, b) {
        final cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (cmp != 0) return cmp;
        return a.createdAt.compareTo(b.createdAt);
      });
    case SortMode.tag:
      list.sort((a, b) {
        final ta = a.tags.isEmpty ? null : a.tags.first.toLowerCase();
        final tb = b.tags.isEmpty ? null : b.tags.first.toLowerCase();
        if (ta == null && tb == null) {
          return b.createdAt.compareTo(a.createdAt);
        }
        if (ta == null) return 1;
        if (tb == null) return -1;
        final cmp = ta.compareTo(tb);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
  }
  return list;
}

List<PrayerListItem> _tagGroupedItems(List<Prayer> prayers) {
  final items = <PrayerListItem>[];
  String? current;
  for (final prayer in prayers) {
    final tag = prayer.tags.isEmpty ? 'Untagged' : prayer.tags.first;
    if (tag != current) {
      current = tag;
      items.add(PrayerSectionHeader(tag));
    }
    items.add(PrayerListEntry(prayer));
  }
  return items;
}
