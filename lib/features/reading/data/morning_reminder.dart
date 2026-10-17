import 'dart:io';

import 'package:flutter/foundation.dart';
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
    _setLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  /// Pacific Time (US), including daylight saving. Android accepts this IANA id.
  static const _pacificZone = 'America/Los_Angeles';

  void _setLocalTimezone() {
    tz.setLocalLocation(tz.getLocation(_pacificZone));
  }

  /// Asks the OS for notification permission. Returns whether alerts are allowed.
  Future<bool> requestPermission() async {
    await ensureInitialized();
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> apply(ReminderPrefs prefs) async {
    try {
      await ensureInitialized();
      // Refresh offset in case DST changed since the last app open.
      _setLocalTimezone();
      await _plugin.cancel(id: _notificationId);
      if (!prefs.enabled) return;

      final allowed = await requestPermission();
      if (!allowed) {
        debugPrint('Selah reminder: notification permission not granted.');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Read and pray',
        channelDescription: 'Morning reminder to read and pray',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
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

      var mode = AndroidScheduleMode.exactAllowWhileIdle;
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final canExact = await android?.canScheduleExactNotifications();
        if (canExact == false) {
          mode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: 'Selah',
        body: 'Read for 10 minutes, then pray for 10 minutes.',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: reminderPayload,
      );
    } catch (e, st) {
      // Never block app launch if scheduling fails.
      debugPrint('Selah reminder: could not schedule ($e)\n$st');
    }
  }
}
