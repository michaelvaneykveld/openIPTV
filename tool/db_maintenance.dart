import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/widgets.dart';

import 'package:openiptv/data/db/dao/artwork_cache_dao.dart';
import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/import_run_dao.dart';
import 'package:openiptv/data/db/dao/maintenance_log_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/database_maintenance.dart';
import 'package:openiptv/data/db/openiptv_db.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();

  final parser = ArgParser()
    ..addFlag(
      'all',
      abbr: 'a',
      negatable: false,
      help: 'Run the full maintenance pipeline (default when no flags set).',
    )
    ..addFlag(
      'vacuum',
      negatable: false,
      help: 'Execute VACUUM if eligible.',
    )
    ..addFlag(
      'analyze',
      negatable: false,
      help: 'Execute ANALYZE if eligible.',
    )
    ..addFlag(
      'sweep',
      negatable: false,
      help: 'Run stale-channel retention sweep.',
    )
    ..addFlag(
      'artwork',
      negatable: false,
      help: 'Prune artwork cache according to configured budgets.',
    )
    ..addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Force selected operations even if cadence checks would skip them.',
    )
    ..addOption(
      'reset-provider',
      valueHelp: 'providerId',
      help: 'Delete a provider and associated records by id.',
    )
    ..addOption(
      'export-import-runs',
      valueHelp: 'path',
      help:
          'Export recorded import runs to JSON at the provided file location.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display usage information.',
    );

  final results = parser.parse(arguments);

  if (results['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final hasExplicitTask = results['vacuum'] as bool ||
      results['analyze'] as bool ||
      results['sweep'] as bool ||
      results['artwork'] as bool;

  final runAll = results['all'] as bool || (!hasExplicitTask);
  final force = results['force'] as bool;

  final db = OpenIptvDb.open();
  final maintenance = DatabaseMaintenance(
    db: db,
    logDao: MaintenanceLogDao(db),
    channelDao: ChannelDao(db),
    artworkDao: ArtworkCacheDao(db),
    config: const DatabaseMaintenanceConfig(),
    databaseFile: await _resolveDbFile(),
  );
  final providerDao = ProviderDao(db);
  final importRunDao = ImportRunDao(db);

  final now = DateTime.now().toUtc();

  try {
    if (runAll) {
      stdout.writeln('Running full maintenance suite...');
      await maintenance.run(now: now, force: force);
    } else {
      if (results['vacuum'] as bool) {
        stdout.writeln('Running VACUUM${force ? ' (forced)' : ''}...');
        await maintenance.runVacuum(now: now, force: force);
      }
      if (results['analyze'] as bool) {
        stdout.writeln('Running ANALYZE${force ? ' (forced)' : ''}...');
        await maintenance.runAnalyze(now: now, force: force);
      }
      if (results['sweep'] as bool) {
        stdout.writeln('Running retention sweep...');
        await maintenance.runRetentionSweep(now: now);
      }
      if (results['artwork'] as bool) {
        stdout.writeln('Pruning artwork cache...');
        await maintenance.runArtworkPrune(force: force);
      }
    }

    final resetProvider = results['reset-provider'] as String?;
    if (resetProvider != null) {
      final id = int.tryParse(resetProvider);
      if (id == null) {
        stderr.writeln('Invalid provider id "$resetProvider".');
        exitCode = 1;
      } else {
        stdout.writeln('Deleting provider $id ...');
        await providerDao.deleteProvider(id);
        stdout.writeln('Provider $id deleted.');
      }
    }

    final exportPath = results['export-import-runs'] as String?;
    if (exportPath != null) {
      stdout.writeln('Exporting import runs to $exportPath ...');
      final runs = await importRunDao.listRecent(limit: 250);
      final jsonPayload = const JsonEncoder.withIndent('  ').convert(
        runs.map((run) => run.toJson()).toList(growable: false),
      );
      await File(exportPath).writeAsString(jsonPayload);
      stdout.writeln('Import run export complete.');
    }
  } finally {
    await db.close();
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: flutter pub run tool/db_maintenance.dart [options]');
  stdout.writeln(parser.usage);
}

Future<File?> _resolveDbFile() async {
  try {
    return await OpenIptvDb.resolveDatabaseFile();
  } catch (_) {
    return null;
  }
}
