import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/domain/prayer.dart';

import '../prayers/fake_prayer_repository.dart';
import '../prayers/test_app.dart';
import 'fake_silence_deps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('timer icon sits left of liturgy and opens prayer timer', (
    tester,
  ) async {
    await pumpSelahApp(tester);

    final timer = find.byTooltip('Prayer timer');
    final liturgy = find.byTooltip('Liturgical prayers');
    final settings = find.byTooltip('Settings');
    expect(timer, findsOneWidget);
    expect(liturgy, findsOneWidget);
    expect(settings, findsOneWidget);

    expect(tester.getCenter(timer).dx, lessThan(tester.getCenter(liturgy).dx));
    expect(
      tester.getCenter(liturgy).dx,
      lessThan(tester.getCenter(settings).dx),
    );

    await tester.tap(timer);
    await tester.pumpAndSettle();

    expect(find.text('Prayer timer'), findsWidgets);
    expect(find.text('Sit in silence.'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('start shows petition name and stop returns to setup', (
    tester,
  ) async {
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    final repo = FakePrayerRepository(clock);
    await repo.createPrayer(
      const NewPrayer(
        name: 'Healing',
        person: 'Jordan',
        request: 'Please heal',
      ),
    );
    final wakeLock = FakeSilenceWakeLock();
    final bell = FakeSilenceBell();

    await pumpSelahApp(
      tester,
      repo: repo,
      silenceBell: bell,
      silenceWakeLock: wakeLock,
    );

    await tester.tap(find.byTooltip('Prayer timer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('14:59'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Sit in silence.'), findsOneWidget);
    expect(wakeLock.enabled, isFalse);
    expect(bell.chimeCount, 0);
  });

  testWidgets('next name skips to the following petition', (tester) async {
    final clock = FakeClock(DateTime(2024, 6, 15, 12));
    final repo = FakePrayerRepository(clock);
    await repo.createPrayer(
      const NewPrayer(name: 'One', person: 'Ada', request: 'a'),
    );
    await repo.createPrayer(
      const NewPrayer(name: 'Two', person: 'Ben', request: 'b'),
    );

    await pumpSelahApp(tester, repo: repo);

    await tester.tap(find.byTooltip('Prayer timer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ada'), findsOneWidget);

    await tester.tap(find.text('Next name'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Ben'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump();
  });
}
