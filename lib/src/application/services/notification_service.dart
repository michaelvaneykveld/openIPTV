import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(initializationSettings);
    _initialized = true;
  }

  Future<int> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int? notificationId,
  }) async {
    await initialize();

    final id = (notificationId ?? scheduledTime.millisecondsSinceEpoch.remainder(1 << 31));
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'openiptv_reminders',
          'Reminders',
          channelDescription: 'Program reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    return id;
  }

  Future<void> cancelNotification(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }
}



