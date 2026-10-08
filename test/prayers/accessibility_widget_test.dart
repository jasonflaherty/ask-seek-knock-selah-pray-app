import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('list usable at 200% text scale', (tester) async {
    await pumpSelahApp(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpFrames(tester, 8);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Add your first prayer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit screen usable at 200% text scale', (tester) async {
    await pumpSelahApp(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.tap(find.text('Add your first prayer'));
    await pumpFrames(tester, 10);

    expect(find.text('Save'), findsOneWidget);
    expect(find.textContaining('Prayer request'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary actions meet labeled tap target guideline', (tester) async {
    await pumpSelahApp(tester);
    await pumpFrames(tester, 5);

    expect(find.text('Add prayer'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
