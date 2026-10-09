import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearTextScaleFactorTestValue();
  });

  testWidgets('primary actions meet labeled tap target guideline', (tester) async {
    await pumpSelahApp(tester);
    await pumpFrames(tester, 5);

    expect(find.text('Add petition'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('list usable at 200% text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;

    await pumpSelahApp(tester);
    await pumpFrames(tester, 8);

    expect(find.text('Ask, Seek, Knock...'), findsOneWidget);
    expect(find.text('Add petition'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit screen usable at 200% text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;

    await pumpSelahApp(tester);
    await tester.tap(find.text('Add petition'));
    await pumpFrames(tester, 10);

    expect(find.text('Add prayer'), findsOneWidget);
    expect(find.textContaining('Visibility'), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
