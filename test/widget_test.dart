import 'package:flutter_test/flutter_test.dart';

import 'package:selah/app/app_config.dart';

import 'prayers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches to empty home', (tester) async {
    await pumpSelahApp(tester);

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
  });
}
