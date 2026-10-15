import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';

final reminderPrefsProvider =
    StateNotifierProvider<ReminderPrefsNotifier, ReminderPrefs>((ref) {
  return ReminderPrefsNotifier(ref.watch(sharedPreferencesProvider));
});

class ReminderPrefs {
  const ReminderPrefs({
    this.enabled = true,
    this.hour = 7,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderPrefs copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderPrefs(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class ReminderPrefsNotifier extends StateNotifier<ReminderPrefs> {
  ReminderPrefsNotifier(this._prefs) : super(_read(_prefs));

  static const _enabledKey = 'read_pray_reminder_enabled';
  static const _hourKey = 'read_pray_reminder_hour';
  static const _minuteKey = 'read_pray_reminder_minute';

  final SharedPreferences _prefs;

  static ReminderPrefs _read(SharedPreferences prefs) {
    return ReminderPrefs(
      enabled: prefs.getBool(_enabledKey) ?? true,
      hour: prefs.getInt(_hourKey) ?? 7,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _prefs.setBool(_enabledKey, enabled);
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _prefs.setInt(_hourKey, hour);
    await _prefs.setInt(_minuteKey, minute);
  }
}
