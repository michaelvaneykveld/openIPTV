import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final telemetryServiceProvider = FutureProvider<TelemetryService>((ref) async {
  final supportDir = await getApplicationSupportDirectory();
  final logDir = Directory(p.join(supportDir.path, 'telemetry'));
  if (!await logDir.exists()) {
    await logDir.create(recursive: true);
  }
  final logFile = File(p.join(logDir.path, 'events.jsonl'));
  final service = TelemetryService(logFile);
  ref.onDispose(service.dispose);
  return service;
});

class TelemetryService {
  TelemetryService(this._file);

  final File _file;
  final _controller = StreamController<TelemetryEvent>.broadcast();

  Stream<TelemetryEvent> watchEvents() => _controller.stream;

  Future<void> logImportMetric({
    required int providerId,
    required String providerKind,
    required String phase,
    Map<String, Object?>? metadata,
  }) {
    return _log(
      category: 'import',
      severity: 'info',
      message: 'Import $phase',
      metadata: {
        'providerId': providerId,
        'providerKind': providerKind,
        ...?metadata,
      },
    );
  }

  Future<void> logQueryLatency({
    required String source,
    required Duration duration,
    bool success = true,
    Map<String, Object?>? metadata,
  }) {
    return _log(
      category: 'query',
      severity: success ? 'info' : 'warn',
      message: '$source latency ${duration.inMilliseconds}ms',
      duration: duration,
      metadata: {
        'source': source,
        'success': success,
        ...?metadata,
      },
    );
  }

  Future<void> logCacheEvent({
    required String cache,
    required String key,
    required bool fromCache,
    int? byteSize,
  }) {
    return _log(
      category: 'cache',
      severity: 'info',
      message: '$cache ${fromCache ? 'hit' : 'miss'}',
      metadata: {
        'key': key,
        'cache': cache,
        'fromCache': fromCache,
        if (byteSize != null) 'bytes': byteSize,
      },
    );
  }

  Future<void> logCrashSafeError({
    required String category,
    required String message,
    Map<String, Object?>? metadata,
  }) {
    return _log(
      category: category,
      severity: 'error',
      message: message,
      metadata: metadata,
    );
  }

  Future<File> exportLogCopy({String? fileName}) async {
    final destination = File(
      fileName ??
          p.join(
            Directory.current.path,
            'build',
            'telemetry',
            'telemetry_export_${DateTime.now().millisecondsSinceEpoch}.jsonl',
          ),
    );
    await destination.parent.create(recursive: true);
    if (await _file.exists()) {
      await _file.copy(destination.path);
    } else {
      await destination.create(recursive: true);
    }
    return destination;
  }

  Future<void> _log({
    required String category,
    required String severity,
    required String message,
    Map<String, Object?>? metadata,
    Duration? duration,
  }) async {
    final event = TelemetryEvent(
      timestamp: DateTime.now().toUtc(),
      category: category,
      severity: severity,
      message: message,
      duration: duration,
      metadata: metadata == null ? const {} : Map.of(metadata),
    );
    _controller.add(event);
    try {
      await _file.writeAsString(
        '${jsonEncode(event.toJson())}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Telemetry log failed: $error');
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}

class TelemetryEvent {
  TelemetryEvent({
    required this.timestamp,
    required this.category,
    required this.severity,
    required this.message,
    this.duration,
    Map<String, Object?>? metadata,
  }) : metadata = metadata == null ? const {} : Map.unmodifiable(metadata);

  final DateTime timestamp;
  final String category;
  final String severity;
  final String message;
  final Duration? duration;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'category': category,
        'severity': severity,
        'message': message,
        if (duration != null) 'durationMs': duration!.inMilliseconds,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}
