Below is a **production‑grade logging & error‑handling blueprint** for a modular IPTV app in **Flutter/Dart** that you can toggle outside the UI by flipping a single line in a configuration file (e.g., `debug=true`). It’s opinionated, field‑tested, and wired for minimal overhead when disabled.

---

## 0) What “best” looks like (in one page)

* **Switch in a config file** (not in UI): read **build‑time** flags (`--dart-define`), a **runtime file** (JSON or `.env`), and (optionally) **Remote Config**. Precedence: *local override file* → *remote config* → *dart‑define* → *defaults*. The flag sets the global **log level** and whether file/remote sinks are attached. ([dart.dev][1])
* **Zero‑cost when off**: if disabled, set `Logger.root.level = Level.OFF` and wire a **No‑Op logger** to modules so calls compile to near‑no‑ops; gate expensive string building behind `isLoggable()` checks. (Package: `logging`.) ([Dart packages][2])
* **Structured, hierarchical logs**: JSON lines with fields: `ts`, `level`, `logger`, `event`, `fields`, `corr` (correlation id), `error`, `stack`. Use named loggers like `iptv.network`, `iptv.auth`, `iptv.epg`, `iptv.db`, `iptv.player`. (Package: `logging`.) ([Dart packages][2])
* **Redaction & safety first**: never log credentials, tokens, MACs or full URLs with secrets; apply a redaction filter for headers/body and follow **OWASP** guidance. ([OWASP Cheat Sheet Series][3])
* **Rotating file logs** (opt‑in): write to app support dir with size‑based rotation & retention; optionally send to Loki/Graylog in QA builds. (Package: `logging_appenders` / `RotatingFileAppender`.) ([Dart packages][4])
* **Global error capture**: wire **FlutterError**, **PlatformDispatcher.onError**, **runZonedGuarded**, and **Isolate.addErrorListener**; feed severe events to **Sentry** (or your choice) with sampling. ([Flutter Docs][5])
* **Module‑local helpers**: modules receive an injected `AppLogger`. If logging is off, DI gives them a `NoopLogger` so the code path exists but **does nothing**.
* **DB and HTTP instrumentation**: turn on **Drift** query tracing and a **Dio** interceptor with **redaction** only when debugging is enabled. ([Drift][6])

---

## 1) How to toggle with a single line (and still keep control)

### A. Build‑time (compile‑time constant; dead‑code elimination)

In CI or locally:

```bash
flutter build apk \
  --dart-define-from-file=env.json
# or
flutter run --dart-define=IPTV_LOGGING=true --dart-define=IPTV_LOG_LEVEL=FINE
```

```dart
// compile-time constants – enable tree-shaking
const kLoggingEnabled = bool.fromEnvironment('IPTV_LOGGING', defaultValue: false);
const kLogLevel = String.fromEnvironment('IPTV_LOG_LEVEL', defaultValue: 'INFO');
```

Dart’s **environment declarations** are evaluated at compile time, which lets the compiler strip branches gated by `const` checks (tree shaking). Use it for coarse controls in release builds. ([dart.dev][1])

> You can also encode flavors that set different **logging levels** per build. Flutter’s flavor docs explicitly call out “logging level” as a flavor‑specific behavior. ([Flutter Docs][7])

### B. Runtime file (edit a line, relaunch the app)

Provide a **human‑editable** file in the app’s **support** directory, e.g.:

`<app-support>/iptv_config.json`

```json
{
  "debug": true,
  "log": {
    "level": "FINE",
    "sinks": ["console", "file"],
    "redact": ["Authorization", "password", "token"]
  }
}
```

Load it at startup with `path_provider` + `dart:io`. (Flutter’s cookbook shows read/write to local files.) ([Flutter Docs][8])

> Want dotenv style? You can also read `.env` via **flutter_dotenv** (runtime) and merge values. ([Dart packages][9])

### C. Remote override (optional)

For production diagnostics, gate **temporary debug windows** with **Firebase Remote Config**. You can remotely switch minimal logging for a user cohort without shipping an update. (Be sure to sample and redact.) ([Firebase][10])

---

## 2) The logging stack (packages & why)

* **Core API**: `package:logging` – leveled, hierarchical, widely used; exposes `Logger.isLoggable()` for **lazy message** evaluation. ([Dart packages][2])
* **Sinks**: `logging_appenders` – console, **RotatingFileAppender** (size‑based rotation and retention), plus **Loki/Graylog/Logz** adapters for QA. ([Dart packages][4])
* **HTTP**: `dio` + `LogInterceptor` (last in chain); *only attach it when debug is true* and ensure **redaction**. ([Dart packages][11])
* **DB**: **Drift** with `logStatements: true`, or better: **QueryInterceptor** to route SQL to your logger (only when debug is on). ([Drift][12])
* **Crashes**: **Sentry Flutter** for uncaught exceptions and breadcrumbs; it automatically wires **PlatformDispatcher.onError / runZonedGuarded**. ([Sentry Docs][13])

---

## 3) Initialization blueprint (one‑time setup)

```dart
// pubspec deps: logging, logging_appenders, path_provider, dio, sentry_flutter (optional)
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path_provider/path_provider.dart';

class LogConfig {
  final bool enabled;
  final Level level;
  final List<String> sinks; // ["console", "file", "remote"]
  final Set<String> redactHeaders;
  const LogConfig({required this.enabled, required this.level, required this.sinks, required this.redactHeaders});
}

Future<LogConfig> loadLogConfig() async {
  // 1) compile-time defaults
  const kLoggingEnabled = bool.fromEnvironment('IPTV_LOGGING', defaultValue: false);
  const kLogLevel = String.fromEnvironment('IPTV_LOG_LEVEL', defaultValue: 'INFO');

  var enabled = kLoggingEnabled;
  var level = _levelFromString(kLogLevel);
  var sinks = <String>['console'];
  var redact = <String>{'authorization','password','token'};

  // 2) runtime file override
  try {
    final dir = await getApplicationSupportDirectory(); // mobile/desktop paths
    final file = File('${dir.path}/iptv_config.json');
    if (await file.exists()) {
      final map = jsonDecode(await file.readAsString()) as Map;
      enabled = (map['debug'] ?? enabled) == true;
      level   = _levelFromString(map['log']?['level'] ?? level.name);
      sinks   = List<String>.from(map['log']?['sinks'] ?? sinks);
      redact  = {...redact, ...List<String>.from(map['log']?['redact'] ?? [])}.map((s)=>s.toLowerCase()).toSet();
    }
  } catch (_) {/* ignore, fallback to defaults */}

  // 3) (optional) remote config override here

  return LogConfig(enabled: enabled, level: level, sinks: sinks, redactHeaders: redact);
}

Level _levelFromString(String s) {
  switch (s.toUpperCase()) {
    case 'OFF': return Level.OFF;
    case 'SEVERE': return Level.SEVERE;
    case 'WARNING': return Level.WARNING;
    case 'INFO': return Level.INFO;
    case 'CONFIG': return Level.CONFIG;
    case 'FINE': return Level.FINE;
    case 'FINER': return Level.FINER;
    case 'FINEST': return Level.FINEST;
    default: return Level.INFO;
  }
}

Future<void> initLogging(LogConfig cfg) async {
  Logger.root.level = cfg.enabled ? cfg.level : Level.OFF;
  Logger.root.children.toList(); // force attach if needed

  // Clear default listeners then attach appenders
  PrintAppender(formatter: const _JsonLineFormatter()).attachToLogger(Logger.root); // console

  if (cfg.enabled && cfg.sinks.contains('file')) {
    final dir = await getApplicationSupportDirectory();
    final path = '${dir.path}/logs/iptv.log';
    RotatingFileAppender(
      baseFilePath: path,
      rotateAtSizeBytes: 2 * 1024 * 1024,
      keepRotateCount: 5,
      formatter: const _JsonLineFormatter(),
    ).attachToLogger(Logger.root);
  }
}

class _JsonLineFormatter extends LogRecordFormatter {
  const _JsonLineFormatter();
  @override
  String format(LogRecord r) => jsonEncode({
    'ts': r.time.toIso8601String(),
    'level': r.level.name,
    'logger': r.loggerName,
    'message': r.message,
    'error': r.error?.toString(),
    'stack': r.stackTrace?.toString(),
    'corr': Zone.current[#corrId],
  });
}
```

* `getApplicationSupportDirectory()` picks a good per‑app path across platforms; you can hand a test engineer a single file to flip. ([Dart packages][14])
* `RotatingFileAppender` rotates logs by size and keeps `N` files—good enough for on‑device diagnostics. ([Dart packages][15])

---

## 4) A tiny **AppLogger** facade (No‑Op when disabled)

```dart
abstract class AppLogger {
  void info(String message, {Map<String, Object?> ctx});
  void warn(String message, {Object? error, StackTrace? stack, Map<String, Object?> ctx});
  void error(String message, {Object? error, StackTrace? stack, Map<String, Object?> ctx});
  bool isFineEnabled();
  void fineLazy(String Function() messageBuilder); // avoids string work unless enabled
}

class NoopLogger implements AppLogger {
  @override void info(_, {ctx}) {}
  @override void warn(_, {error, stack, ctx}) {}
  @override void error(_, {error, stack, ctx}) {}
  @override bool isFineEnabled() => false;
  @override void fineLazy(_) {}
}

class StdLogger implements AppLogger {
  final Logger _l;
  StdLogger(String name) : _l = Logger(name);
  @override void info(String m, {Map<String,Object?> ctx=const{}}) => _l.info('$m ${jsonEncode(ctx)}');
  @override void warn(String m,{Object? error, StackTrace? stack, Map<String,Object?> ctx=const{}}) =>
      _l.warning('$m ${jsonEncode(ctx)}', error, stack);
  @override void error(String m,{Object? error, StackTrace? stack, Map<String,Object?> ctx=const{}}) =>
      _l.severe('$m ${jsonEncode(ctx)}', error, stack);
  @override bool isFineEnabled() => _l.isLoggable(Level.FINE);
  @override void fineLazy(String Function() mb) { if (_l.isLoggable(Level.FINE)) _l.fine(mb()); }
}
```

> Using `Logger.isLoggable(level)` avoids creating expensive messages when the level is disabled. ([Stack Overflow][16])

Inject `AppLogger` per module: when logging is disabled, provide `NoopLogger`; otherwise `StdLogger('iptv.network')`, etc.

---

## 5) Error handling that never misses (and doesn’t spam)

Wire once in `main()`:

```dart
Future<void> main() async {
  final cfg = await loadLogConfig();
  await initLogging(cfg);

  // Global Flutter framework errors
  FlutterError.onError = (details) {
    Logger('iptv.flutter').severe('FlutterError', details.exception, details.stack);
  }; // docs: FlutterError.onError. :contentReference[oaicite:20]{index=20}

  // Unhandled errors (post-3.3) – platform layer
  PlatformDispatcher.instance.onError = (error, stack) {
    Logger('iptv.global').severe('Uncaught', error, stack);
    return true; // handled
  }; // docs mention PlatformDispatcher for top-level errors. :contentReference[oaicite:21]{index=21}

  // Zone to carry correlation-id (also catches uncaught async errors)
  runZonedGuarded(() {
    return runApp(MyApp());
  }, (error, stack) {
    Logger('iptv.zone').severe('Uncaught (zone)', error, stack);
  }, zoneValues: {#corrId: _newCorrId()}); // zones carry local values. :contentReference[oaicite:22]{index=22}
}
```

For **worker isolates**, forward uncaught errors to the root isolate via `Isolate.addErrorListener`—Flutter explicitly notes that `PlatformDispatcher.onError` won’t see errors from child isolates. ([Flutter API Docs][17])

> If you add Sentry, it automatically wires **runZonedGuarded / PlatformDispatcher.onError** to capture crashes. ([Sentry Docs][13])

---

## 6) Network logging with **redaction** (Xtream/Stalker/M3U)

```dart
import 'package:dio/dio.dart';

Interceptor makeRedactingLogInterceptor(Set<String> redactHeaders, AppLogger log) {
  String _scrubHeaders(Headers h) {
    final m = <String,String>{};
    h.forEach((k, v) {
      final key = k.toLowerCase();
      m[k] = redactHeaders.contains(key) ? '***REDACTED***' : v.join(',');
    });
    return jsonEncode(m);
  }

  return InterceptorsWrapper(
    onRequest: (options, handler) {
      if (log.isFineEnabled()) {
        log.fineLazy(() => 'REQ ${options.method} ${options.uri} '
            'headers=${_scrubHeaders(options.headers)}');
      }
      handler.next(options);
    },
    onResponse: (resp, handler) {
      log.info('RES ${resp.requestOptions.uri} status=${resp.statusCode}');
      handler.next(resp);
    },
    onError: (e, handler) {
      log.warn('HTTP ERROR ${e.requestOptions.uri}', error: e, stack: e.stackTrace);
      handler.next(e);
    },
  );
}
```

* `LogInterceptor` in `dio` should be **last** in the chain. If you use it, still wrap it with redaction. ([Dart packages][11])
* Never log credentials or tokens (OWASP MASWE‑0001 advises removal/redaction in production). ([OWASP Mobile Application Security][18])

---

## 7) Database logging (Drift)

* During debugging, start your DB with `logStatements: true`, which prints SQL + bound variables, or use **QueryInterceptor** to pipe them to your logger. ([Drift][12])

```dart
final db = LazyDatabase(() async {
  final file = File(p.join((await getApplicationSupportDirectory()).path, 'iptv.sqlite'));
  return NativeDatabase(file, logStatements: cfg.enabled); // simple toggle
});
```

> For richer formatting & routing, apply a custom `QueryInterceptor` only when `cfg.enabled` is true. ([Drift][6])

---

## 8) Player & EPG‑specific events (what to log and why)

Keep logs **meaningful**, not noisy (LogRocket’s guidance). Prefer events with **context** over raw dumps. ([LogRocket Blog][19])

* **Auth/handshake**: provider type, server host, response time, outcome (no secrets).
* **Playlist ingestion**: M3U size, channel count, categories, parse time, dedup count.
* **EPG import**: XMLTV size (bytes, compressed/uncompressed), program count, time window, parse time, failures.
* **Playback**: URL scheme (HLS/TS), startup time (time to first frame), stalls (#, total stall time), average bitrate, resolution switches. These are common streaming QoE metrics. ([BytePlus][20])
* **DB writes**: rows inserted/updated, transaction time, vacuum/compaction events.

If you use `media_kit`, you can surface its internal logs into your logger or mute them depending on your configuration; the project exposes log controls for diagnostics. ([GitHub][21])

---

## 9) Privacy & store compliance

* **Don’t log PII** or secrets; keep credentials, device identifiers, and tokens out of logs. Follow **OWASP Logging Cheat Sheet** and **MASWE‑0001**. ([OWASP Cheat Sheet Series][3])
* Your **App Store / Google Play “Data Safety”** disclosures must reflect any log collection or sharing, even for diagnostics. Plan your toggles accordingly. ([Apple Developer][22])

---

## 10) Putting it all together (app startup)

```dart
Future<void> bootstrap() async {
  final cfg = await loadLogConfig();
  await initLogging(cfg);

  // Build the DI graph:
  final AppLogger netLog = cfg.enabled ? StdLogger('iptv.network') : NoopLogger();
  final AppLogger dbLog  = cfg.enabled ? StdLogger('iptv.db')      : NoopLogger();
  final AppLogger epgLog = cfg.enabled ? StdLogger('iptv.epg')     : NoopLogger();
  final dio = Dio()..interceptors.add(makeRedactingLogInterceptor(
      cfg.redactHeaders, netLog));

  // Drift, only verbose if debug:
  final db = await _openDriftDatabase(cfg, dbLog);

  // From here, modules receive AppLogger via constructor:
  // XtreamAdapter(dio, logger: netLog) etc.
}
```

---

## 11) Testing the toggle (what to assert)

* **Unit**: with `cfg.enabled=false`, loggers are `NoopLogger`; **no file** is created; `Logger.root.level==OFF`.
* **Integration**: enable logging via `iptv_config.json`, relaunch, verify a rotated file exists and contains **JSON lines** with your correlation id.
* **HTTP**: assert that `Authorization` and `password` never appear in log output (redaction unit test).
* **Error flow**: throw in build/layout (caught by `FlutterError`), in a `Future` (zone), and in an **isolate** (`Isolate.addErrorListener`) and verify capture. ([Flutter Docs][5])

---

## 12) Nice‑to‑have add‑ons

* **Remote switches** for a subset of users via **Firebase Remote Config** (short TTL, low sampling). ([Firebase][10])
* **Breadcrumbs & crash analytics** via **Sentry** (exceptions + network breadcrumbs). ([Sentry Docs][13])
* **Ship logs on demand**: a hidden action that zips the rotating log directory into an email share intent (only when `debug=true`).
* **VS Code launch**: put `--dart-define` values in `launch.json` so your team runs the same config locally. ([dartcode.org][23])

---

## 13) If you want prebuilt pieces (GOAT‑ish, modular)

* **`logging_appenders`**: production‑ready appenders, including a **rotating file** appender and remote backends (Loki/Graylog/Logz). Great with `package:logging`. ([Dart packages][4])
* **`logger`**: popular dev‑friendly logger with filters/printers; easy to extend to files (but less “enterprise” than `logging` + appenders). ([Dart packages][24])
* **`flutter_logs`**: file‑based logging with export & JSON (ELK‑style) if you want a batteries‑included solution. ([Dart packages][25])
* **`firebase_remote_config`**: ship toggles remotely without UI. ([Dart packages][26])
* **Drift tracing**: official docs & FAQ (log statements / interceptors). ([Drift][6])

---

## 14) Why this approach is safe & future‑proof

* Uses the **official Flutter/Dart hooks** for errors (FlutterError / PlatformDispatcher / zones), which their docs endorse. ([Flutter Docs][5])
* Toggle can be **build‑time** (`--dart-define`, flavors) or **runtime file**; both are supported by official docs and common practice. ([dart.dev][1])
* **PII‑safe** by default (OWASP guidance), which helps with **App Store / Play** privacy declarations. ([OWASP Cheat Sheet Series][3])
* File logs **rotate** to avoid storage bloat; appenders are **asynchronous** and robust. ([Dart packages][15])
* HTTP & DB logging are **opt‑in** and automatically redacted / filtered.


[1]: https://dart.dev/libraries/core/environment-declarations?utm_source=chatgpt.com "Configuring apps with compilation environment declarations - Dart"
[2]: https://pub.dev/documentation/logging/latest/?utm_source=chatgpt.com "logging - Dart API docs - Pub"
[3]: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html?utm_source=chatgpt.com "Logging - OWASP Cheat Sheet Series"
[4]: https://pub.dev/documentation/logging_appenders/latest/?utm_source=chatgpt.com "logging_appenders - Dart API docs - Pub"
[5]: https://docs.flutter.dev/testing/errors?utm_source=chatgpt.com "Handling errors in Flutter"
[6]: https://drift.simonbinder.eu/examples/tracing/?utm_source=chatgpt.com "Tracing database operations - Drift"
[7]: https://docs.flutter.dev/deployment/flavors?utm_source=chatgpt.com "Flavors (Android) | Flutter"
[8]: https://docs.flutter.dev/cookbook/persistence/reading-writing-files?utm_source=chatgpt.com "Read and write files - Flutter"
[9]: https://pub.dev/packages/flutter_dotenv?utm_source=chatgpt.com "flutter_dotenv | Flutter package - Pub"
[10]: https://firebase.google.com/docs/remote-config/?utm_source=chatgpt.com "Firebase Remote Config"
[11]: https://pub.dev/documentation/dio/latest/dio/LogInterceptor-class.html?utm_source=chatgpt.com "LogInterceptor class - dio library - Dart API - Pub"
[12]: https://drift.simonbinder.eu/faq/?utm_source=chatgpt.com "FAQ - Simon Binder"
[13]: https://docs.sentry.io/platforms/dart/guides/flutter/usage/?utm_source=chatgpt.com "Usage | Sentry for Flutter"
[14]: https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationDocumentsDirectory.html?utm_source=chatgpt.com "getApplicationDocumentsDirectory function - path_provider library ..."
[15]: https://pub.dev/documentation/logging_appenders/latest/logging_appenders/RotatingFileAppender-class.html?utm_source=chatgpt.com "RotatingFileAppender class - logging_appenders library - Dart API - Pub"
[16]: https://stackoverflow.com/questions/69689138/developer-log-does-not-print-log?utm_source=chatgpt.com "flutter - developer.log does not print log - Stack Overflow"
[17]: https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html?utm_source=chatgpt.com "onError property - PlatformDispatcher class - dart:ui library - Flutter"
[18]: https://mas.owasp.org/MASWE/MASVS-STORAGE/MASWE-0001/?utm_source=chatgpt.com "MASWE-0001: Insertion of Sensitive Data into Logs - OWASP"
[19]: https://blog.logrocket.com/flutter-logging-best-practices/?utm_source=chatgpt.com "Flutter logging best practices - LogRocket Blog"
[20]: https://www.byteplus.com/en/topic/41435?utm_source=chatgpt.com "The common video streaming performance metrics"
[21]: https://github.com/media-kit/media-kit/issues/260?utm_source=chatgpt.com "[Question] Disabling console logs? · Issue #260 · media-kit ... - GitHub"
[22]: https://developer.apple.com/app-store/user-privacy-and-data-use/?utm_source=chatgpt.com "User Privacy and Data Use - App Store - Apple Developer"
[23]: https://dartcode.org/docs/using-dart-define-in-flutter/?utm_source=chatgpt.com "Using --dart-define in Flutter - Dart Code - Dart & Flutter support for ..."
[24]: https://pub.dev/packages/logger?utm_source=chatgpt.com "logger | Dart package - Pub"
[25]: https://pub.dev/packages/flutter_logs?utm_source=chatgpt.com "flutter_logs | Flutter package - Pub"
[26]: https://pub.dev/packages/firebase_remote_config?utm_source=chatgpt.com "firebase_remote_config | Flutter package - Pub"
