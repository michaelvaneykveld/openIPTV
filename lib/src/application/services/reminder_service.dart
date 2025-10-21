import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/services/notification_service.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/reminder.dart';
import 'package:openiptv/utils/app_logger.dart';

class ReminderManager {
  ReminderManager() {
    _restoreReminders();
  }

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Reminder>> loadReminders(String portalId) async {
    final rows = await _databaseHelper.getUpcomingReminders(DateTime.now());
    return rows
        .map(Reminder.fromMap)
        .where((reminder) => reminder.portalId == portalId)
        .toList();
  }

  Future<int?> scheduleReminder({
    required Channel channel,
    required String portalId,
    required String programTitle,
    required DateTime startTime,
  }) async {
    final reminderTime = startTime.subtract(const Duration(minutes: 1));
    final notificationId = await NotificationService.instance
        .scheduleNotification(
          title: programTitle,
          body: 'Upcoming on ${channel.name}',
          scheduledTime: reminderTime.isBefore(DateTime.now())
              ? DateTime.now()
              : reminderTime,
        );

    final reminder = Reminder(
      portalId: portalId,
      channelId: channel.id,
      programTitle: programTitle,
      startTime: startTime,
      notificationId: notificationId,
      createdAt: DateTime.now(),
    );

    final id = await _databaseHelper.insertReminder(reminder);
    if (id <= 0) {
      await NotificationService.instance.cancelNotification(notificationId);
      return null;
    }
    return id;
  }

  Future<void> cancelReminder(int reminderId) async {
    final rows = await _databaseHelper.getUpcomingReminders(DateTime.now());
    final reminderRow = rows.firstWhere(
      (row) => row['id'] == reminderId,
      orElse: () => <String, dynamic>{},
    );
    if (reminderRow.isNotEmpty) {
      final reminder = Reminder.fromMap(reminderRow);
      if (reminder.notificationId != null) {
        await NotificationService.instance.cancelNotification(
          reminder.notificationId!,
        );
      }
    }
    await _databaseHelper.deleteReminder(reminderId);
  }

  Future<void> _restoreReminders() async {
    final upcoming = await _databaseHelper.getUpcomingReminders(DateTime.now());
    for (final row in upcoming) {
      final reminder = Reminder.fromMap(row);
      if (reminder.notificationId == null ||
          reminder.startTime.isBefore(DateTime.now())) {
        continue;
      }
      try {
        final channelName = await _resolveChannelName(
          reminder.portalId,
          reminder.channelId,
        );
        await NotificationService.instance.scheduleNotification(
          title: reminder.programTitle,
          body: channelName != null
              ? 'Upcoming on $channelName'
              : 'Upcoming: ${reminder.programTitle}',
          scheduledTime: reminder.startTime.subtract(
            const Duration(minutes: 1),
          ),
        );
      } catch (e, stackTrace) {
        appLogger.w(
          'Failed to reschedule reminder ${reminder.id} (${reminder.channelId})',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<String?> _resolveChannelName(String portalId, String channelId) async {
    final rows = await _databaseHelper.getAllChannels(portalId);
    for (final row in rows) {
      if (row[DatabaseHelper.columnChannelId] == channelId) {
        return Channel.fromDbMap(row).name;
      }
    }
    return null;
  }
}

final reminderManagerProvider = Provider<ReminderManager>((ref) {
  return ReminderManager();
});
