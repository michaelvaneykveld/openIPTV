import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:openiptv/src/utils/url_redaction.dart';

import 'slow_query_log_writer.dart' as slow_log;

typedef SlowQueryEventSink = FutureOr<void> Function(SlowQueryEvent event);

class SlowQueryInterceptor extends QueryInterceptor {
  SlowQueryInterceptor({
    Duration threshold = const Duration(milliseconds: 120),
    SlowQueryEventSink? onEvent,
  }) : _threshold = threshold,
       _onEvent = onEvent ?? SlowQueryLogger.instance.record;

  final Duration _threshold;
  final SlowQueryEventSink _onEvent;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _trace<List<Map<String, Object?>>>(
      executor,
      operation: 'select',
      statement: statement,
      args: args,
      rowsRead: (rows) => rows.length,
      run: () => executor.runSelect(statement, args),
    );
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _trace<int>(
      executor,
      operation: 'insert',
      statement: statement,
      args: args,
      rowsAffected: (value) => value == 0 ? null : 1,
      run: () => executor.runInsert(statement, args),
    );
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _trace<int>(
      executor,
      operation: 'update',
      statement: statement,
      args: args,
      rowsAffected: (value) => value,
      run: () => executor.runUpdate(statement, args),
    );
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _trace<int>(
      executor,
      operation: 'delete',
      statement: statement,
      args: args,
      rowsAffected: (value) => value,
      run: () => executor.runDelete(statement, args),
    );
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _trace<void>(
      executor,
      operation: 'custom',
      statement: statement,
      args: args,
      run: () => executor.runCustom(statement, args),
    );
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    return _trace<void>(
      executor,
      operation: 'batch',
      statement: 'batch:${statements.statements.length}',
      args: const [],
      run: () => executor.runBatched(statements),
    );
  }

  Future<T> _trace<T>(
    QueryExecutor executor, {
    required String operation,
    required String statement,
    required List<Object?> args,
    required Future<T> Function() run,
    int? Function(T result)? rowsRead,
    int? Function(T result)? rowsAffected,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await run();
      sw.stop();
      await _maybeEmit(
        operation: operation,
        statement: statement,
        args: args,
        duration: sw.elapsed,
        success: true,
        rowsRead: rowsRead == null ? null : rowsRead(result),
        rowsAffected: rowsAffected == null ? null : rowsAffected(result),
      );
      return result;
    } catch (error) {
      sw.stop();
      await _maybeEmit(
        operation: operation,
        statement: statement,
        args: args,
        duration: sw.elapsed,
        success: false,
        error: error,
      );
      rethrow;
    }
  }

  Future<void> _maybeEmit({
    required String operation,
    required String statement,
    required List<Object?> args,
    required Duration duration,
    required bool success,
    Object? error,
    int? rowsRead,
    int? rowsAffected,
  }) async {
    if (duration < _threshold && success) {
      return;
    }
    final event = SlowQueryEvent(
      timestamp: DateTime.now().toUtc(),
      operation: operation,
      duration: duration,
      success: success,
      sql: statement,
      argsPreview: args.isEmpty ? null : _formatArgs(args),
      argsCount: args.length,
      rowsRead: rowsRead,
      rowsAffected: rowsAffected,
      error: error?.toString(),
    );
    await _onEvent(event);
  }

  String _formatArgs(List<Object?> args) {
    final safeArgs = args.map((value) {
      if (value == null) return null;
      final text = value.toString();
      if (text.length <= 128) return text;
      return '${text.substring(0, 125)}...';
    }).toList();
    final json = jsonEncode(safeArgs);
    return redactSensitiveText(json);
  }
}

class SlowQueryEvent {
  SlowQueryEvent({
    required this.timestamp,
    required this.operation,
    required this.duration,
    required this.success,
    required this.sql,
    this.argsPreview,
    this.argsCount,
    this.rowsRead,
    this.rowsAffected,
    this.error,
  });

  final DateTime timestamp;
  final String operation;
  final Duration duration;
  final bool success;
  final String sql;
  final String? argsPreview;
  final int? argsCount;
  final int? rowsRead;
  final int? rowsAffected;
  final String? error;

  Map<String, Object?> toJson() => {
    'ts': timestamp.toIso8601String(),
    'op': operation,
    'durationMs': duration.inMilliseconds,
    'success': success,
    'sqlHash': sql.hashCode,
    'sql': _truncate(sql),
    if (argsPreview != null) 'args': argsPreview,
    if (argsCount != null) 'argsCount': argsCount,
    if (rowsRead != null) 'rowsRead': rowsRead,
    if (rowsAffected != null) 'rowsAffected': rowsAffected,
    if (error != null) 'error': error,
  };

  String _truncate(String value, {int max = 1024}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }
}

class SlowQueryLogger {
  SlowQueryLogger._();

  static final SlowQueryLogger instance = SlowQueryLogger._();

  Future<void> record(SlowQueryEvent event) async {
    try {
      await slow_log.writeSlowQueryLine(jsonEncode(event.toJson()));
    } catch (error) {
      // swallow logging failures silently in production builds
      assert(() {
        // keep signal during development
        debugPrint('SlowQueryLogger failed: $error');
        return true;
      }());
    }
  }
}
