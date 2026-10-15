import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:selah/app/app.dart';
import 'package:selah/app/router.dart';
import 'package:selah/core/providers.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/metrics/application/metrics_providers.dart';
import 'package:selah/features/silence/application/silence_session_notifier.dart';
import 'package:selah/features/silence/domain/silence_bell.dart';
import 'package:selah/features/silence/domain/silence_wake_lock.dart';
import 'package:selah/features/verses/data/verse_asset_loader.dart';
import 'package:selah/features/verses/domain/verse.dart';
import 'package:selah/features/verses/domain/verse_suggester.dart';

import '../metrics/fake_usage_repository.dart';
import '../silence/fake_silence_deps.dart';
import 'fake_prayer_repository.dart';

final _emptyDataset = VerseDataset(
  translation: 'KJV',
  version: 1,
  verses: const [],
  synonyms: const {},
);

class _NoopSuggester implements VerseSuggester {
  @override
  Verse? byId(String id) => null;

  @override
  List<Verse> byIds(List<String> ids) => const [];

  @override
  Future<List<Verse>> suggest(String request, {int limit = 6}) async =>
      const [];
}

class TestApp {
  TestApp({required this.container, required this.repo, required this.clock});

  final ProviderContainer container;
  final FakePrayerRepository repo;
  final FakeClock clock;
}

Future<void> pumpFrames(WidgetTester tester, [int count = 5]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<TestApp> pumpSelahApp(
  WidgetTester tester, {
  FakePrayerRepository? repo,
  SilenceBell? silenceBell,
  SilenceWakeLock? silenceWakeLock,
  int Function()? silenceShuffleSeed,
}) async {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  SharedPreferences.setMockInitialValues({});
  appRouter.go('/');
  final prefs = await SharedPreferences.getInstance();
  final clock = FakeClock(DateTime(2024, 6, 15, 12));
  final repository = repo ?? FakePrayerRepository(clock);
  final bell = silenceBell ?? FakeSilenceBell();
  final wakeLock = silenceWakeLock ?? FakeSilenceWakeLock();

  final usage = FakeUsageRepository();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(clock),
      prayerRepositoryProvider.overrideWithValue(repository),
      usageRepositoryProvider.overrideWithValue(usage),
      verseDatasetProvider.overrideWithValue(_emptyDataset),
      verseSuggesterProvider.overrideWithValue(_NoopSuggester()),
      silenceBellProvider.overrideWithValue(bell),
      silenceWakeLockProvider.overrideWithValue(wakeLock),
      if (silenceShuffleSeed != null)
        silenceShuffleSeedProvider.overrideWithValue(silenceShuffleSeed),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SelahApp()),
  );
  await pumpFrames(tester);

  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    container.dispose();
    repository.dispose();
    usage.dispose();
  });

  return TestApp(container: container, repo: repository, clock: clock);
}
