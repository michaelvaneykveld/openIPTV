import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/database/database_helper.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/core/models/recording.dart';
import 'package:openiptv/utils/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RecordingManager {
  RecordingManager() {
    _restoreScheduledRecordings();
  }

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final HttpClient _httpClient = HttpClient();
  final Map<int, _ActiveRecording> _activeRecordings = {};
  final Map<int, Timer> _scheduledStarts = {};

  Future<List<Recording>> loadPortalRecordings(String portalId) async {
    final rows = await _databaseHelper.getAllRecordings(portalId);
    return rows.map(Recording.fromMap).toList();
  }

  Future<int?> startRecordingNow({
    required Channel channel,
    required String portalId,
    Duration? duration,
  }) async {
    final now = DateTime.now();
    final recording = Recording(
      portalId: portalId,
      channelId: channel.id,
      title: channel.name,
      startTime: now,
      endTime: duration != null ? now.add(duration) : null,
      status: RecordingStatus.recording,
      createdAt: now,
    );

    final recordingId = await _databaseHelper.insertRecording(recording);
    if (recordingId <= 0) {
      return null;
    }

    final recordingWithId = recording.copyWith(id: recordingId);
    await _startRecordingStream(recordingWithId, channel);
    return recordingId;
  }

  Future<int?> scheduleRecording({
    required Channel channel,
    required String portalId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('Recording end time must be after start time');
    }
    final recording = Recording(
      portalId: portalId,
      channelId: channel.id,
      title: channel.name,
      startTime: startTime,
      endTime: endTime,
      status: RecordingStatus.scheduled,
      createdAt: DateTime.now(),
    );
    final recordingId = await _databaseHelper.insertRecording(recording);
    if (recordingId <= 0) {
      return null;
    }
    _scheduleStart(recording.copyWith(id: recordingId), channel);
    return recordingId;
  }

  Future<void> stopRecording(int recordingId) async {
    final active = _activeRecordings.remove(recordingId);
    if (active == null) {
      return;
    }
    await active.subscription.cancel();
    await active.sink.flush();
    await active.sink.close();
    active.stopTimer?.cancel();

    await _databaseHelper.updateRecording(
      active.recording.copyWith(
        status: RecordingStatus.completed,
        endTime: DateTime.now(),
        filePath: active.outputFile.path,
      ),
    );
  }

  Future<void> cancelRecording(int recordingId) async {
    await stopRecording(recordingId);
    await _databaseHelper.deleteRecording(recordingId);
    final timer = _scheduledStarts.remove(recordingId);
    timer?.cancel();
  }

  Future<void> _startRecordingStream(
    Recording recording,
    Channel channel,
  ) async {
    final streamUrl = channel.streamUrl ?? channel.cmd;
    if (streamUrl == null) {
      appLogger.e('RecordingManager: No stream URL for channel ${channel.id}');
      await _databaseHelper.updateRecording(
        recording.copyWith(
          status: RecordingStatus.failed,
          endTime: DateTime.now(),
        ),
      );
      return;
    }

    final file = await _createRecordingFile(
      recording.portalId,
      recording.title,
      recording.startTime,
    );
    final request = await _httpClient.getUrl(Uri.parse(streamUrl));
    final response = await request.close();
    final sink = file.openWrite();

    final updatedRecording = recording.copyWith(
      filePath: file.path,
      status: RecordingStatus.recording,
    );
    await _databaseHelper.updateRecording(updatedRecording);

    final subscription = response.listen(
      sink.add,
      onError: (error, stackTrace) async {
        await sink.flush();
        await sink.close();
        appLogger.e(
          'RecordingManager: error while recording ${recording.id}',
          error: error,
          stackTrace: stackTrace,
        );
        await _databaseHelper.updateRecording(
          updatedRecording.copyWith(
            status: RecordingStatus.failed,
            endTime: DateTime.now(),
          ),
        );
        _activeRecordings.remove(recording.id);
      },
      onDone: () async {
        await sink.flush();
        await sink.close();
        if (_activeRecordings.remove(recording.id) != null) {
          await _databaseHelper.updateRecording(
            updatedRecording.copyWith(
              status: RecordingStatus.completed,
              endTime: DateTime.now(),
            ),
          );
        }
      },
      cancelOnError: true,
    );

    final active = _ActiveRecording(
      recording: updatedRecording,
      subscription: subscription,
      sink: sink,
      outputFile: file,
    );

    if (recording.endTime != null) {
      final remaining = recording.endTime!.difference(DateTime.now());
      if (!remaining.isNegative) {
        active.stopTimer = Timer(remaining, () => stopRecording(recording.id!));
      }
    }

    _activeRecordings[recording.id!] = active;
  }

  Future<File> _createRecordingFile(
    String portalId,
    String channelName,
    DateTime date,
  ) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'recordings', portalId));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final sanitized = channelName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '${date.millisecondsSinceEpoch}_$sanitized.ts';
    return File(p.join(directory.path, fileName));
  }

  Future<void> _restoreScheduledRecordings() async {
    final pending = await _databaseHelper.getPendingRecordings(DateTime.now());
    for (final row in pending) {
      final recording = Recording.fromMap(row);
      final channel = await _fetchChannel(
        recording.portalId,
        recording.channelId,
      );
      if (channel == null) {
        continue;
      }
      if (recording.status == RecordingStatus.scheduled) {
        _scheduleStart(recording, channel);
      } else if (recording.status == RecordingStatus.recording) {
        final now = DateTime.now();
        final remaining = recording.endTime?.difference(now);
        await _startRecordingStream(recording, channel);
        if (remaining != null && !remaining.isNegative) {
          _activeRecordings[recording.id!]?.stopTimer = Timer(
            remaining,
            () => stopRecording(recording.id!),
          );
        }
      }
    }
  }

  void _scheduleStart(Recording recording, Channel channel) {
    final now = DateTime.now();
    final delay = recording.startTime.difference(now);
    if (delay.isNegative) {
      final remaining = recording.endTime?.difference(now);
      _startRecordingStream(
        recording.copyWith(status: RecordingStatus.recording),
        channel,
      );
      if (remaining != null && !remaining.isNegative) {
        _activeRecordings[recording.id!]?.stopTimer = Timer(
          remaining,
          () => stopRecording(recording.id!),
        );
      }
      return;
    }
    final timer = Timer(delay, () async {
      await _startRecordingStream(
        recording.copyWith(status: RecordingStatus.recording),
        channel,
      );
      _scheduledStarts.remove(recording.id);
    });
    _scheduledStarts[recording.id!] = timer;
  }

  Future<Channel?> _fetchChannel(String portalId, String channelId) async {
    final rows = await _databaseHelper.getAllChannels(portalId);
    for (final row in rows) {
      if (row[DatabaseHelper.columnChannelId] == channelId) {
        return Channel.fromDbMap(row);
      }
    }
    return null;
  }

  void dispose() {
    for (final active in _activeRecordings.values) {
      active.subscription.cancel();
      active.sink.close();
      active.stopTimer?.cancel();
    }
    for (final timer in _scheduledStarts.values) {
      timer.cancel();
    }
    _activeRecordings.clear();
    _scheduledStarts.clear();
  }
}

class _ActiveRecording {
  _ActiveRecording({
    required this.recording,
    required this.subscription,
    required this.sink,
    required this.outputFile,
  });

  final Recording recording;
  final StreamSubscription<List<int>> subscription;
  final IOSink sink;
  final File outputFile;
  Timer? stopTimer;
}

final recordingManagerProvider = Provider<RecordingManager>((ref) {
  final manager = RecordingManager();
  ref.onDispose(manager.dispose);
  return manager;
});
