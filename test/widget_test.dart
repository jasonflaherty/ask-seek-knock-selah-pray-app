import 'package:flutter_test/flutter_test.dart';

import 'prayers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches to empty home', (tester) async {
    await pumpSelahApp(tester);

    expect(find.text('Ask, Seek, Knock...'), findsOneWidget);
    expect(find.text('Add petition'), findsOneWidget);
  });
}
