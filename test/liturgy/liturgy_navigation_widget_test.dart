import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:selah/app/app.dart';
import 'package:selah/app/router.dart';
import 'package:selah/core/providers.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/liturgy/data/liturgy_catalog.dart';
import 'package:selah/features/silence/application/silence_session_notifier.dart';
import 'package:selah/features/verses/data/verse_asset_loader.dart';
import 'package:selah/features/verses/domain/verse.dart';
import 'package:selah/features/verses/domain/verse_suggester.dart';

import '../prayers/fake_prayer_repository.dart';
import '../prayers/test_app.dart';
import '../silence/fake_silence_deps.dart';

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

final _liturgyPrayers = LiturgyCatalog.parse(
  File('assets/liturgy/collects.json').readAsStringSync(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLiturgyApp(WidgetTester tester) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    appRouter.go('/');
    final prefs = await SharedPreferences.getInstance();
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    final repository = FakePrayerRepository(clock);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(clock),
        prayerRepositoryProvider.overrideWithValue(repository),
        verseDatasetProvider.overrideWithValue(_emptyDataset),
        verseSuggesterProvider.overrideWithValue(_NoopSuggester()),
        silenceBellProvider.overrideWithValue(FakeSilenceBell()),
        silenceWakeLockProvider.overrideWithValue(FakeSilenceWakeLock()),
        liturgyPrayersProvider.overrideWith((ref) async => _liturgyPrayers),
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
    });
  }

  Future<void> openLiturgy(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Liturgical prayers'));
    await pumpFrames(tester, 20);
    expect(find.text('Contents'), findsOneWidget);
  }

  testWidgets('liturgy icon sits left of settings and opens collects', (
    tester,
  ) async {
    await pumpLiturgyApp(tester);

    final liturgy = find.byTooltip('Liturgical prayers');
    final settings = find.byTooltip('Settings');
    expect(liturgy, findsOneWidget);
    expect(settings, findsOneWidget);

    final liturgyDx = tester.getCenter(liturgy).dx;
    final settingsDx = tester.getCenter(settings).dx;
    expect(liturgyDx, lessThan(settingsDx));

    await openLiturgy(tester);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('contents jump scrolls to a collect title', (tester) async {
    await pumpLiturgyApp(tester);
    await openLiturgy(tester);

    final tocLink = find.byKey(const ValueKey('toc-ash-wednesday'));
    await tester.scrollUntilVisible(
      tocLink,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, 5);
    await tester.tap(tocLink);
    await pumpFrames(tester, 30);

    expect(
      find.textContaining('Create and make in us new and contrite hearts'),
      findsWidgets,
    );
  });

  testWidgets('favoriting adds a Favorites section', (tester) async {
    await pumpLiturgyApp(tester);
    await openLiturgy(tester);

    expect(find.text('Favorites'), findsNothing);

    await tester.tap(
      find.byKey(
        const ValueKey('favorite-today-the-second-sunday-after-trinity'),
      ),
    );
    await pumpFrames(tester, 10);

    expect(find.text('Favorites'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('favorite-saved-the-second-sunday-after-trinity'),
      ),
      findsOneWidget,
    );
  });
}
