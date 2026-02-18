import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class TelegramScrapeLogger {
  TelegramScrapeLogger._();

  static final TelegramScrapeLogger instance = TelegramScrapeLogger._();
  static final Future<File> _logFileFuture = _init();

  static Future<File> _init() async {
    final dir = Directory.systemTemp;
    final file = File(
      '${dir.path}${Platform.pathSeparator}openiptv_telegram_scrape.log',
    );
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  static Future<String> get logPath async {
    final file = await _logFileFuture;
    return file.path;
  }

  static void log(String message, {String tag = 'telegram'}) {
    if (kReleaseMode) return;
    final timestamp = DateTime.now().toIso8601String();
    final line = '[$timestamp][$tag] $message\n';
    unawaited(_append(line));
  }

  static void error(String message, Object error, {String tag = 'telegram'}) {
    if (kReleaseMode) return;
    final timestamp = DateTime.now().toIso8601String();
    final line = '[$timestamp][$tag][error] $message :: $error\n';
    unawaited(_append(line));
  }

  static Future<void> _append(String line) async {
    try {
      final file = await _logFileFuture;
      await file.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {
      // Swallow logging errors to avoid cascading failures.
    }
  }
}
