import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/providers/credentials_provider.dart';
import 'package:openiptv/src/application/services/recording_service.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/recording.dart';

class RecordingCenterScreen extends ConsumerStatefulWidget {
  const RecordingCenterScreen({super.key});

  @override
  ConsumerState<RecordingCenterScreen> createState() =>
      _RecordingCenterScreenState();
}

class _RecordingCenterScreenState extends ConsumerState<RecordingCenterScreen> {
  Future<List<Recording>>? _loadFuture;

  @override
  Widget build(BuildContext context) {
    final portalIdAsync = ref.watch(portalIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recordings')),
      floatingActionButton: portalIdAsync.when(
        data: (portalId) => portalId == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showRecordingSheet(context, portalId),
                icon: const Icon(Icons.add),
                label: const Text('New recording'),
              ),
        error: (context, _) => null,
        loading: () => null,
      ),
      body: portalIdAsync.when(
        data: (portalId) {
          if (portalId == null) {
            return const Center(child: Text('No active portal.'));
          }

          _loadFuture ??= ref
              .read(recordingManagerProvider)
              .loadPortalRecordings(portalId);

          return FutureBuilder<List<Recording>>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final recordings = snapshot.data ?? [];
              if (recordings.isEmpty) {
                return const Center(child: Text('No recordings yet.'));
              }

              return ListView.separated(
                itemCount: recordings.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final recording = recordings[index];
                  return ListTile(
                    title: Text(recording.title),
                    subtitle: Text(_recordingSubtitle(recording)),
                    trailing: _buildActions(context, portalId, recording),
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

  String _recordingSubtitle(Recording recording) {
    final statusLabel = recording.status.name;
    final start = recording.startTime.toLocal();
    final startText =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} '
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final end = recording.endTime?.toLocal();
    final endText = end != null
        ? ' -> ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'
        : '';
    return '$statusLabel - $startText$endText';
  }

  Widget _buildActions(
    BuildContext context,
    String portalId,
    Recording recording,
  ) {
    final manager = ref.read(recordingManagerProvider);
    switch (recording.status) {
      case RecordingStatus.recording:
        return IconButton(
          icon: const Icon(Icons.stop),
          onPressed: () async {
            await manager.stopRecording(recording.id!);
            _refresh(portalId);
          },
          tooltip: 'Stop recording',
        );
      case RecordingStatus.scheduled:
        return IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () async {
            await manager.cancelRecording(recording.id!);
            _refresh(portalId);
          },
          tooltip: 'Cancel recording',
        );
      default:
        if (recording.filePath == null) {
          return const SizedBox.shrink();
        }
        return IconButton(
          icon: const Icon(Icons.folder_open),
          tooltip: 'Show file location',
          onPressed: () => _showRecordingFile(context, recording.filePath!),
        );
    }
  }

  Future<void> _showRecordingSheet(
    BuildContext context,
    String portalId,
  ) async {
    final action = await showModalBottomSheet<_RecordingChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fiber_manual_record),
              title: const Text('Record now'),
              onTap: () =>
                  Navigator.of(context).pop(_RecordingChoice.immediate),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedule recording'),
              onTap: () => Navigator.of(context).pop(_RecordingChoice.schedule),
            ),
          ],
        ),
      ),
    );

    switch (action) {
      case _RecordingChoice.immediate:
        if (!context.mounted) return;
        await _recordNow(context, portalId);
        break;
      case _RecordingChoice.schedule:
        if (!context.mounted) return;
        await _scheduleRecording(context, portalId);
        break;
      default:
        break;
    }
  }

  Future<void> _recordNow(BuildContext context, String portalId) async {
    final channel = await _chooseChannel(context, portalId);
    if (!context.mounted) return;
    if (channel == null) return;

    final durationMinutes = await _promptForNumber(
      context,
      'Recording duration (minutes)',
      '60',
    );
    if (!context.mounted) return;
    final duration = durationMinutes != null
        ? Duration(minutes: durationMinutes)
        : null;

    await ref
        .read(recordingManagerProvider)
        .startRecordingNow(
          channel: channel,
          portalId: portalId,
          duration: duration,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recording started for ${channel.name}.')),
    );
    _refresh(portalId);
  }

  Future<void> _scheduleRecording(BuildContext context, String portalId) async {
    final channel = await _chooseChannel(context, portalId);
    if (!context.mounted) return;
    if (channel == null) return;

    final start = await _pickDateTime(context, 'Choose start time');
    if (!context.mounted) return;
    if (start == null) return;
    final end = await _pickDateTime(context, 'Choose end time');
    if (!context.mounted) return;
    if (end == null || end.isBefore(start)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    await ref
        .read(recordingManagerProvider)
        .scheduleRecording(
          channel: channel,
          portalId: portalId,
          startTime: start,
          endTime: end,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recording scheduled for ${channel.name}.')),
    );
    _refresh(portalId);
  }

  Future<Channel?> _chooseChannel(BuildContext context, String portalId) async {
    final rows = await DatabaseHelper.instance.getAllChannels(portalId);
    if (!context.mounted) return null;
    final channels = rows.map((row) => Channel.fromDbMap(row)).toList();

    if (channels.isEmpty) {
      if (!context.mounted) return null;
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

  Future<int?> _promptForNumber(
    BuildContext context,
    String title,
    String initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(context).pop(value);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
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
    if (!context.mounted) return null;
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: title,
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _refresh(String portalId) {
    setState(() {
      _loadFuture = ref
          .read(recordingManagerProvider)
          .loadPortalRecordings(portalId);
    });
  }

  void _showRecordingFile(BuildContext context, String path) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Recording saved at $path')));
  }
}

enum _RecordingChoice { immediate, schedule }
