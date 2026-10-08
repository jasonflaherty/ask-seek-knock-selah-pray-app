import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:selah/app/app.dart';
import 'package:selah/core/providers.dart';
import 'package:selah/core/utils/clock.dart';

import 'fake_prayer_repository.dart';

class TestApp {
  TestApp({
    required this.container,
    required this.repo,
    required this.clock,
  });

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
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final clock = FakeClock(DateTime(2024, 6, 15, 12));
  final repository = repo ?? FakePrayerRepository(clock);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(clock),
      prayerRepositoryProvider.overrideWithValue(repository),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SelahApp(),
    ),
  );
  await pumpFrames(tester);

  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, 2);
    container.dispose();
    repository.dispose();
  });

  return TestApp(container: container, repo: repository, clock: clock);
}
