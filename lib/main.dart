import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/db/app_database.dart';
import 'core/providers.dart';
import 'core/utils/clock.dart';
import 'features/metrics/presentation/usage_host.dart';
import 'features/prayers/data/drift_prayer_repository.dart';
import 'features/prayers/data/initial_prayers.dart';
import 'features/reading/application/reminder_prefs.dart';
import 'features/reading/data/morning_reminder.dart';
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

  // Reminder must not block launch if the OS rejects the schedule.
  try {
    await MorningReminder().apply(ReminderPrefs(
      enabled: prefs.getBool('read_pray_reminder_enabled') ?? true,
      hour: prefs.getInt('read_pray_reminder_hour') ?? 7,
      minute: prefs.getInt('read_pray_reminder_minute') ?? 0,
    ));
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        verseDatasetProvider.overrideWithValue(dataset),
      ],
      child: const UsageHost(child: SelahApp()),
    ),
  );
}
