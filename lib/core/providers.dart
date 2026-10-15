import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/analytics/application/event_logger.dart';
import '../features/liturgy/application/liturgy_favorites_notifier.dart';
import '../features/liturgy/data/liturgy_catalog.dart';
import '../features/liturgy/domain/liturgical_calendar.dart';
import '../features/liturgy/domain/liturgical_prayer.dart';
import '../features/prayers/application/home_meditation_offset_notifier.dart';
import '../features/prayers/data/drift_prayer_repository.dart';
import '../features/prayers/data/home_meditation_catalog.dart';
import '../features/prayers/domain/home_meditation.dart';
import '../features/prayers/domain/prayer_repository.dart';
import '../features/verses/data/drift_custom_verse_repository.dart';
import '../features/verses/data/keyword_verse_suggester.dart';
import '../features/verses/data/strategy_verse_suggester.dart';
import '../features/verses/data/text_normalizer.dart';
import '../features/verses/data/verse_asset_loader.dart';
import '../features/verses/domain/custom_verse_repository.dart';
import '../features/verses/domain/verse_catalog.dart';
import '../features/verses/domain/verse_suggester.dart';
import 'db/app_database.dart';
import 'utils/clock.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main',
  );
});

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return DriftPrayerRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  );
});

final eventLoggerProvider = Provider<EventLogger>((ref) {
  return EventLogger(
    ref.watch(prayerRepositoryProvider),
    ref.watch(clockProvider),
  );
});

final verseDatasetProvider = Provider<VerseDataset>((ref) {
  throw UnimplementedError('verseDatasetProvider must be overridden in main');
});

final verseSuggesterProvider = Provider<VerseSuggester>((ref) {
  final dataset = ref.watch(verseDatasetProvider);
  final normalizer = TextNormalizer(dataset.synonyms);
  final keywords = KeywordVerseSuggester(dataset, normalizer);
  return StrategyVerseSuggester(keywords, dataset.strategies);
});

final customVerseRepositoryProvider = Provider<CustomVerseRepository>((ref) {
  return DriftCustomVerseRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  );
});

final verseCatalogProvider = Provider<VerseCatalog>((ref) {
  return VerseCatalog(
    suggester: ref.watch(verseSuggesterProvider),
    custom: ref.watch(customVerseRepositoryProvider),
  );
});

final liturgyCatalogProvider = Provider<LiturgyCatalog>((ref) {
  return LiturgyCatalog();
});

final liturgyPrayersProvider = FutureProvider<List<LiturgicalPrayer>>((
  ref,
) async {
  return ref.watch(liturgyCatalogProvider).load();
});

final liturgicalCalendarProvider = Provider<LiturgicalCalendar>((ref) {
  return const LiturgicalCalendar();
});

final liturgyTodayProvider = Provider<TodaySelection>((ref) {
  final calendar = ref.watch(liturgicalCalendarProvider);
  final now = ref.watch(clockProvider).now();
  return calendar.todayAt(now);
});

final liturgyFavoritesProvider =
    StateNotifierProvider<LiturgyFavoritesNotifier, Set<String>>((ref) {
  return LiturgyFavoritesNotifier(ref.watch(sharedPreferencesProvider));
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

/// Whether the home-screen meditation verse banner is shown.
final homeVerseVisibleProvider =
    StateNotifierProvider<HomeVerseVisibleNotifier, bool>((ref) {
      return HomeVerseVisibleNotifier(ref.watch(sharedPreferencesProvider));
    });

final homeMeditationCatalogProvider = Provider<HomeMeditationCatalog>((ref) {
  return HomeMeditationCatalog();
});

final homeMeditationVersesProvider =
    FutureProvider<List<HomeMeditationVerse>>((ref) async {
  return ref.watch(homeMeditationCatalogProvider).load();
});

final homeMeditationOffsetProvider = StateNotifierProvider<
    HomeMeditationOffsetNotifier, HomeMeditationOffset>((ref) {
  return HomeMeditationOffsetNotifier(ref.watch(sharedPreferencesProvider));
});

/// Scripture for the journal home banner on the local calendar day.
final homeMeditationTodayProvider = Provider<HomeMeditationVerse?>((ref) {
  final verses = ref.watch(homeMeditationVersesProvider).valueOrNull;
  if (verses == null) return null;
  final now = ref.watch(clockProvider).now();
  final stored = ref.watch(homeMeditationOffsetProvider);
  final offset =
      stored.dayKey == homeMeditationDayKey(now) ? stored.offset : 0;
  return homeMeditationForDay(verses, now, offset: offset);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  static const _key = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_key, value);
  }
}

class HomeVerseVisibleNotifier extends StateNotifier<bool> {
  HomeVerseVisibleNotifier(this._prefs) : super(_prefs.getBool(_key) ?? true);

  static const _key = 'home_verse_visible';
  final SharedPreferences _prefs;

  Future<void> setVisible(bool visible) async {
    state = visible;
    await _prefs.setBool(_key, visible);
  }
}
