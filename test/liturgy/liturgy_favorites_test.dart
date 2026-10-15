import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah/features/liturgy/application/liturgy_favorites_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggle persists favorite ids', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = LiturgyFavoritesNotifier(prefs);

    expect(notifier.state, isEmpty);

    await notifier.toggle('ash-wednesday');
    expect(notifier.isFavorite('ash-wednesday'), isTrue);
    expect(
      prefs.getStringList(LiturgyFavoritesNotifier.prefsKey),
      ['ash-wednesday'],
    );

    await notifier.toggle('evening-perils');
    expect(notifier.state, containsAll(['ash-wednesday', 'evening-perils']));

    await notifier.toggle('ash-wednesday');
    expect(notifier.isFavorite('ash-wednesday'), isFalse);
    expect(
      prefs.getStringList(LiturgyFavoritesNotifier.prefsKey),
      ['evening-perils'],
    );
  });

  test('loads favorites from preferences', () async {
    SharedPreferences.setMockInitialValues({
      LiturgyFavoritesNotifier.prefsKey: ['morning-grace'],
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = LiturgyFavoritesNotifier(prefs);
    expect(notifier.state, {'morning-grace'});
  });
}
