import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:openiptv/data/db/openiptv_db.dart';

Future<void> main(List<String> arguments) async {
  final destinationArg = arguments.isNotEmpty ? arguments.first : '';
  final outputPath = destinationArg.isEmpty
      ? p.join(
          Directory.current.path,
          'build',
          'exports',
          'openiptv_snapshot.sqlite',
        )
      : destinationArg;

  final destFile = File(outputPath);
  await destFile.parent.create(recursive: true);

  try {
    final source = await OpenIptvDb.resolveDatabaseFile();
    if (!await source.exists()) {
      stderr.writeln('No database file found at ${source.path}.');
      return;
    }
    await source.copy(destFile.path);
    stdout.writeln('Database snapshot exported to ${destFile.path}');
    stdout.writeln(
      'Inspect with drift_devtools:\n'
      '  dart run drift_devtools --db=${destFile.path}',
    );
  } catch (error) {
    stderr.writeln('Snapshot export failed: $error');
    rethrow;
  }
}
