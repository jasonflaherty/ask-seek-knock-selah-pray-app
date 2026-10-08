import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/analytics/application/event_logger.dart';
import '../features/prayers/data/drift_prayer_repository.dart';
import '../features/prayers/domain/prayer_repository.dart';
import '../features/verses/data/keyword_verse_suggester.dart';
import '../features/verses/data/text_normalizer.dart';
import '../features/verses/data/verse_asset_loader.dart';
import '../features/verses/domain/verse_suggester.dart';
import 'db/app_database.dart';
import 'utils/clock.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
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
  return KeywordVerseSuggester(dataset, normalizer);
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
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
