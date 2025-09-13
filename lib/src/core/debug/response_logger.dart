
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResponseLog {
  final DateTime timestamp;
  final String method;
  final String url;
  final int? statusCode;
  final dynamic data;

  ResponseLog({
    required this.timestamp,
    required this.method,
    required this.url,
    this.statusCode,
    this.data,
  });
}

class ResponseLogger {
  static final List<ResponseLog> _logs = [];

  static void addLog(ResponseLog log) {
    _logs.insert(0, log); // Add to the beginning of the list
    if (_logs.length > 50) { // Keep the last 50 logs
      _logs.removeLast();
    }
  }

  static List<ResponseLog> get logs => _logs;
}

final responseLoggerProvider = Provider<List<ResponseLog>>((ref) {
  return ResponseLogger.logs;
});
