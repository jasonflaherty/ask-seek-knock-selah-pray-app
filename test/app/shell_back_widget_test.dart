import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:selah/app/router.dart';

import '../prayers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('system back pops timer then liturgy onto the journal', (
    tester,
  ) async {
    await pumpSelahApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(appRouter.canPop(), isFalse);

    await tester.tap(find.byTooltip('Prayer timer'));
    await pumpFrames(tester, 20);
    expect(find.text('Sit in silence.'), findsOneWidget);
    expect(appRouter.canPop(), isTrue);

    await tester.tap(find.byTooltip('Liturgical prayers'));
    await pumpFrames(tester, 20);
    expect(find.text('Today'), findsOneWidget);
    expect(appRouter.canPop(), isTrue);

    final poppedLiturgy = await tester.binding.handlePopRoute();
    await pumpFrames(tester, 20);
    expect(poppedLiturgy, isTrue);
    expect(find.text('Sit in silence.'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    final poppedTimer = await tester.binding.handlePopRoute();
    await pumpFrames(tester, 20);
    expect(poppedTimer, isTrue);
    expect(find.text('Ask, Seek, Knock...'), findsOneWidget);
    expect(find.text('Sit in silence.'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(appRouter.canPop(), isFalse);
  });

  testWidgets('system back from settings returns to the previous tab', (
    tester,
  ) async {
    await pumpSelahApp(tester);

    await tester.tap(find.byTooltip('Prayer timer'));
    await pumpFrames(tester, 20);
    expect(find.text('Sit in silence.'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await pumpFrames(tester, 20);
    expect(find.text('Settings'), findsOneWidget);
    expect(appRouter.canPop(), isTrue);

    final handled = await tester.binding.handlePopRoute();
    await pumpFrames(tester, 20);
    expect(handled, isTrue);
    expect(find.text('Sit in silence.'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('system back on the journal leaves the app open', (
    tester,
  ) async {
    await pumpSelahApp(tester);
    expect(find.text('Ask, Seek, Knock...'), findsOneWidget);
    expect(appRouter.canPop(), isFalse);

    await tester.binding.handlePopRoute();
    await pumpFrames(tester, 20);

    expect(find.text('Ask, Seek, Knock...'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.path, '/');
  });
}
