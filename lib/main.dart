import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/db/app_database.dart';
import 'core/providers.dart';
import 'core/utils/clock.dart';
import 'features/prayers/data/drift_prayer_repository.dart';
import 'features/prayers/data/initial_prayers.dart';
import 'features/verses/data/verse_asset_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dataset = await VerseAssetLoader().load();

  final db = AppDatabase();
  try {
    final repo = DriftPrayerRepository(db, const SystemClock());
    await InitialPrayersSeeder(repo, prefs).seedIfNeeded();
  } finally {
    await db.close();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        verseDatasetProvider.overrideWithValue(dataset),
      ],
      child: const SelahApp(),
    ),
  );
}
