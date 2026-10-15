import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../application/reminder_prefs.dart';

final morningReminderProvider = Provider<MorningReminder>((ref) {
  return MorningReminder();
});

/// Schedules the daily read-and-pray reminder on the device.
class MorningReminder {
  MorningReminder() : _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'selah_read_pray';
  static const _notificationId = 710;
  static const reminderPayload = 'read_pray';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> ensureInitialized() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> apply(ReminderPrefs prefs) async {
    await ensureInitialized();
    await _plugin.cancel(id: _notificationId);
    if (!prefs.enabled) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Read and pray',
      channelDescription: 'Morning reminder to read and pray',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      prefs.hour,
      prefs.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Selah',
      body: 'Read for 10 minutes, then pray for 10 minutes.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reminderPayload,
    );
  }
}
