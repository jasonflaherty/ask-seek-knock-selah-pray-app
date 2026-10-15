import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiturgyFavoritesNotifier extends StateNotifier<Set<String>> {
  LiturgyFavoritesNotifier(this._prefs) : super(_read(_prefs));

  static const prefsKey = 'liturgy_favorite_ids';

  final SharedPreferences _prefs;

  static Set<String> _read(SharedPreferences prefs) {
    final list = prefs.getStringList(prefsKey) ?? const <String>[];
    return list.toSet();
  }

  bool isFavorite(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    final next = Set<String>.from(state);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = next;
    await _prefs.setStringList(prefsKey, next.toList()..sort());
  }
}
