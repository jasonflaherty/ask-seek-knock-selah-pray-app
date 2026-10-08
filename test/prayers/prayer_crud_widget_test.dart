import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:selah/features/prayers/domain/prayer.dart';

import 'test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add prayer happy path', (tester) async {
    final app = await pumpSelahApp(tester);

    await tester.tap(find.text('Add your first prayer'));
    await pumpFrames(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Mom');
    await tester.enterText(fields.at(1), 'Healing for her back pain');
    await tester.tap(find.text('Save'));
    await pumpFrames(tester, 10);

    expect(find.text('Mom'), findsOneWidget);
    expect(find.textContaining('Healing'), findsWidgets);

    expect(app.repo.allPrayers, hasLength(1));
    expect(app.repo.allPrayers.single.name, 'Mom');
  });

  testWidgets('validation errors when fields empty', (tester) async {
    await pumpSelahApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await pumpFrames(tester);

    await tester.tap(find.text('Save'));
    await pumpFrames(tester);

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Prayer request is required'), findsOneWidget);
  });

  testWidgets('answer and undo via repository keeps data consistent', (tester) async {
    final app = await pumpSelahApp(tester);
    final id = await app.repo.createPrayer(
      const NewPrayer(name: 'Friend', request: 'Peace and rest for them today'),
    );
    await app.repo.setAnswered(id, answered: true);
    expect(app.repo.allPrayers.single.isAnswered, isTrue);

    await app.repo.setAnswered(id, answered: false);
    expect(app.repo.allPrayers.single.isAnswered, isFalse);
  });
}
