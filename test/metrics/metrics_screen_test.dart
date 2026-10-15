import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah/app/theme.dart';
import 'package:selah/core/providers.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/metrics/application/metrics_providers.dart';
import 'package:selah/features/metrics/presentation/metrics_screen.dart';
import 'package:selah/features/metrics/presentation/usage_host.dart';
import 'package:selah/features/prayers/domain/prayer.dart';

import '../prayers/fake_prayer_repository.dart';
import '../prayers/test_app.dart';
import 'fake_usage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings opens metrics', (tester) async {
    await pumpSelahApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await pumpFrames(tester, 20);
    await tester.ensureVisible(find.text('Open metrics'));
    await tester.tap(find.text('Open metrics'));
    await pumpFrames(tester, 20);

    expect(find.text('Active and answered'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Time open'), findsOneWidget);
    expect(find.text('No petitions yet.'), findsOneWidget);
    expect(find.text('No tags yet.'), findsOneWidget);
    expect(find.textContaining('0m in the last 14 days'), findsOneWidget);
  });

  testWidgets('metrics graphs show petitions, tags, and open time', (
    tester,
  ) async {
    await _pumpMetrics(tester);
    expect(find.text('1 active · 1 answered'), findsOneWidget);
    expect(find.text('family'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Week of Jun 10: 1 active, 1 answered'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('family, 2 petitions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('in the last 14 days'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('30m in the last 14 days'), findsOneWidget);

    await tester.ensureVisible(find.text('30 days'));
    await tester.tap(find.text('30 days'));
    await tester.pump();
    expect(find.textContaining('30m in the last 30 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metrics screen fits a narrow screen at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await _pumpMetrics(tester);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('usage host records foreground time', (tester) async {
    final usage = FakeUsageRepository();
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      usage.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(clock),
          usageRepositoryProvider.overrideWithValue(usage),
        ],
        child: const UsageHost(child: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(usage.sessions, hasLength(1));
    clock.advance(const Duration(minutes: 6));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(usage.sessions.single.duration, const Duration(minutes: 6));
  });
}

Future<void> _pumpMetrics(WidgetTester tester) async {
  final clock = FakeClock(DateTime(2024, 6, 15, 12));
  final prayers = FakePrayerRepository(clock);
  final usage = FakeUsageRepository();

  clock.set(DateTime(2024, 6, 1, 9));
  await prayers.createPrayer(
    const NewPrayer(name: 'Mom', request: 'Healing', tags: ['family']),
  );
  clock.set(DateTime(2024, 6, 11, 9));
  final workId = await prayers.createPrayer(
    const NewPrayer(name: 'Work', request: 'Wisdom', tags: ['family', 'work']),
  );
  clock.set(DateTime(2024, 6, 14, 9));
  await prayers.setAnswered(workId, answered: true);
  clock.set(DateTime(2024, 6, 15, 12));
  await usage.beginSession(DateTime(2024, 6, 15, 11, 30));
  await usage.markOpenUntil(1, DateTime(2024, 6, 15, 12));

  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    prayers.dispose();
    usage.dispose();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(clock),
        prayerRepositoryProvider.overrideWithValue(prayers),
        usageRepositoryProvider.overrideWithValue(usage),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const MetricsScreen()),
    ),
  );
  await tester.pump();
}
