import 'dart:io';

import 'package:path/path.dart' as p;

Future<File>? _logFile;

Future<void> writeSlowQueryLine(String line) async {
  final file = await _resolveLogFile();
  await file.writeAsString('$line\n', mode: FileMode.append);
}

Future<File> _resolveLogFile() async {
  final existing = _logFile;
  if (existing != null) {
    return existing;
  }
  final future = _createLogFile();
  _logFile = future;
  return future;
}

Future<File> _createLogFile() async {
  final root = Directory(
    p.join(Directory.systemTemp.path, 'openiptv', 'telemetry'),
  );
  if (!(await root.exists())) {
    await root.create(recursive: true);
  }
  return File(p.join(root.path, 'slow_queries.jsonl'));
}
