import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/application/services/reminder_service.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/reminder.dart';

class ReminderCenterScreen extends ConsumerStatefulWidget {
  const ReminderCenterScreen({super.key});

  @override
  ConsumerState<ReminderCenterScreen> createState() =>
      _ReminderCenterScreenState();
}

class _ReminderCenterScreenState extends ConsumerState<ReminderCenterScreen> {
  Future<List<Reminder>>? _loadFuture;

  @override
  Widget build(BuildContext context) {
    final portalIdAsync = ref.watch(portalIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: portalIdAsync.when(
        data: (portalId) => portalId == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _createReminder(context, portalId),
                icon: const Icon(Icons.add_alert),
                label: const Text('New reminder'),
              ),
        error: (_, __) => null,
        loading: () => null,
      ),
      body: portalIdAsync.when(
        data: (portalId) {
          if (portalId == null) {
            return const Center(child: Text('No active portal.'));
          }

          _loadFuture ??= ref
              .read(reminderManagerProvider)
              .loadReminders(portalId);

          return FutureBuilder<List<Reminder>>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final reminders = snapshot.data ?? [];
              if (reminders.isEmpty) {
                return const Center(child: Text('No reminders scheduled.'));
              }

              return ListView.separated(
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return ListTile(
                    title: Text(reminder.programTitle),
                    subtitle: Text(_formatReminderSubtitle(reminder)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await ref
                            .read(reminderManagerProvider)
                            .cancelReminder(reminder.id!);
                        _refresh(portalId);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
        error: (error, _) => Center(child: Text('Error: ${error.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _formatReminderSubtitle(Reminder reminder) {
    final start = reminder.startTime.toLocal();
    final date =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final time =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    return 'Channel: ${reminder.channelId} - $date $time';
  }

  Future<void> _createReminder(BuildContext context, String portalId) async {
    final channel = await _chooseChannel(context, portalId);
    if (channel == null) return;

    final startTime = await _pickDateTime(context, 'Program start time');
    if (startTime == null) return;

    final title = await _promptForText(context, 'Program title', channel.name);
    if (title == null || title.trim().isEmpty) return;

    await ref
        .read(reminderManagerProvider)
        .scheduleReminder(
          channel: channel,
          portalId: portalId,
          programTitle: title.trim(),
          startTime: startTime,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for ${channel.name}.')),
    );
    _refresh(portalId);
  }

  Future<Channel?> _chooseChannel(BuildContext context, String portalId) async {
    final rows = await DatabaseHelper.instance.getAllChannels(portalId);
    final channels = rows.map((row) => Channel.fromDbMap(row)).toList();

    if (channels.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No channels available.')));
      return null;
    }

    Channel? selected = channels.first;
    return showDialog<Channel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select channel'),
        content: StatefulBuilder(
          builder: (context, setState) => DropdownButton<Channel>(
            value: selected,
            items: channels
                .map(
                  (channel) => DropdownMenuItem(
                    value: channel,
                    child: Text(channel.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, String title) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: title,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<String?> _promptForText(
    BuildContext context,
    String title,
    String initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _refresh(String portalId) {
    setState(() {
      _loadFuture = ref.read(reminderManagerProvider).loadReminders(portalId);
    });
  }
}
