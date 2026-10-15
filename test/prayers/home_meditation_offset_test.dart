import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/prayers/application/home_meditation_offset_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late HomeMeditationOffsetNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notifier = HomeMeditationOffsetNotifier(prefs);
  });

  test('starts at zero for today', () {
    expect(notifier.offsetFor(DateTime(2026, 1, 1)), 0);
  });

  test('advance increments within the same day', () async {
    final day = DateTime(2026, 1, 1, 10);
    await notifier.advance(day);
    expect(notifier.offsetFor(day), 1);
    await notifier.advance(day);
    expect(notifier.offsetFor(day), 2);
  });

  test('offset resets on a new calendar day', () async {
    await notifier.advance(DateTime(2026, 1, 1));
    expect(notifier.offsetFor(DateTime(2026, 1, 1)), 1);
    expect(notifier.offsetFor(DateTime(2026, 1, 2)), 0);
  });
}
