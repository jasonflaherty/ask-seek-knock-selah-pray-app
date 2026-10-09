import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../prayers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('liturgy icon sits left of settings and opens collects', (
    tester,
  ) async {
    await pumpSelahApp(tester);

    final liturgy = find.byTooltip('Liturgical prayers');
    final settings = find.byTooltip('Settings');
    expect(liturgy, findsOneWidget);
    expect(settings, findsOneWidget);

    final liturgyDx = tester.getCenter(liturgy).dx;
    final settingsDx = tester.getCenter(settings).dx;
    expect(liturgyDx, lessThan(settingsDx));

    await tester.tap(liturgy);
    await tester.pumpAndSettle();

    expect(find.text('Liturgical prayers'), findsWidgets);
    expect(find.text('Morning'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Lighten our darkness'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Evening', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Lighten our darkness'), findsOneWidget);
  });
}
