import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/home_meditation.dart';

/// Manual advance from the day's home meditation verse.
///
/// Offset is kept for the local calendar day in [dayKey]. When the day
/// changes, [offsetFor] returns 0 until the user rotates again.
class HomeMeditationOffsetNotifier extends StateNotifier<HomeMeditationOffset> {
  HomeMeditationOffsetNotifier(this._prefs) : super(_read(_prefs));

  static const _offsetKey = 'home_meditation_offset';
  static const _dayKey = 'home_meditation_offset_day';

  final SharedPreferences _prefs;

  static HomeMeditationOffset _read(SharedPreferences prefs) {
    return HomeMeditationOffset(
      dayKey: prefs.getString(_dayKey) ?? '',
      offset: prefs.getInt(_offsetKey) ?? 0,
    );
  }

  int offsetFor(DateTime now) {
    final key = homeMeditationDayKey(now);
    if (state.dayKey != key) return 0;
    return state.offset;
  }

  Future<void> advance(DateTime now) async {
    final key = homeMeditationDayKey(now);
    final next = state.dayKey == key ? state.offset + 1 : 1;
    state = HomeMeditationOffset(dayKey: key, offset: next);
    await _prefs.setString(_dayKey, key);
    await _prefs.setInt(_offsetKey, next);
  }
}

class HomeMeditationOffset {
  const HomeMeditationOffset({
    required this.dayKey,
    required this.offset,
  });

  final String dayKey;
  final int offset;
}
