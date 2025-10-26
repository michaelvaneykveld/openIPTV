import 'package:meta/meta.dart';

/// Identifies the provider family targeted by a discovery implementation.
enum ProviderKind { stalker, xtream, m3u }

/// Signature for log sinks interested in probe progress. Every record is
/// pre-sanitised (user info and query parameters stripped) so downstream log
/// pipelines do not require additional redaction.
typedef DiscoveryLogSink = void Function(DiscoveryProbeRecord record);

/// Container for knobs shared across discovery adapters.
@immutable
class DiscoveryOptions {
  static const DiscoveryOptions defaults = DiscoveryOptions._();

  /// Whether HTTP clients should accept self-signed TLS certificates.
  final bool allowSelfSignedTls;

  /// Extra headers appended to every probe request (e.g., custom auth).
  final Map<String, String> headers;

  /// Optional User-Agent override applied to probe requests.
  final String? userAgent;

  /// Optional MAC address propagated to adapters that need STB identity.
  final String? macAddress;

  /// Optional callback receiving telemetry for each probe attempt.
  final DiscoveryLogSink? logSink;

  const DiscoveryOptions._({
    this.allowSelfSignedTls = false,
    this.headers = const {},
    this.userAgent,
    this.macAddress,
    this.logSink,
  });

  factory DiscoveryOptions({
    bool allowSelfSignedTls = false,
    Map<String, String>? headers,
    String? userAgent,
    String? macAddress,
    DiscoveryLogSink? logSink,
  }) {
    return DiscoveryOptions._(
      allowSelfSignedTls: allowSelfSignedTls,
      headers: headers == null ? const {} : Map.unmodifiable(Map.of(headers)),
      userAgent: userAgent,
      macAddress: macAddress,
      logSink: logSink,
    );
  }
}

/// Represents the locked-in base endpoint returned by a discovery run.
@immutable
class DiscoveryResult {
  final ProviderKind kind;
  final Uri lockedBase;
  final Map<String, String> hints;
  final DiscoveryTelemetry telemetry;

  const DiscoveryResult._({
    required this.kind,
    required this.lockedBase,
    required this.hints,
    required this.telemetry,
  });

  factory DiscoveryResult({
    required ProviderKind kind,
    required Uri lockedBase,
    Map<String, String>? hints,
    DiscoveryTelemetry telemetry = DiscoveryTelemetry.empty,
  }) {
    return DiscoveryResult._(
      kind: kind,
      lockedBase: lockedBase,
      hints: hints == null ? const {} : Map.unmodifiable(Map.of(hints)),
      telemetry: telemetry,
    );
  }
}

/// Aggregates probe records so callers can surface diagnostics or analytics.
@immutable
class DiscoveryTelemetry {
  static const DiscoveryTelemetry empty = DiscoveryTelemetry._();

  final List<DiscoveryProbeRecord> probes;

  const DiscoveryTelemetry._({this.probes = const []});

  factory DiscoveryTelemetry({List<DiscoveryProbeRecord>? probes}) {
    return DiscoveryTelemetry._(
      probes: probes == null ? const [] : List.unmodifiable(probes),
    );
  }

  bool get hasProbes => probes.isNotEmpty;
}

/// Captures the outcome of a single HTTP probe issued during discovery.
@immutable
class DiscoveryProbeRecord {
  final ProviderKind kind;
  final String stage;
  final Uri uri;
  final Duration elapsed;
  final int? statusCode;
  final bool matchedSignature;
  final Object? error;

  const DiscoveryProbeRecord({
    required this.kind,
    required this.stage,
    required this.uri,
    required this.elapsed,
    this.statusCode,
    this.matchedSignature = false,
    this.error,
  });

  bool get isFailure => error != null || !matchedSignature;
}

/// Exception thrown when discovery cannot lock onto a working endpoint.
class DiscoveryException implements Exception {
  final String message;
  final DiscoveryTelemetry telemetry;

  const DiscoveryException(
    this.message, {
    this.telemetry = DiscoveryTelemetry.empty,
  });

  @override
  String toString() => 'DiscoveryException: $message';
}

/// Shared contract implemented by provider-specific discovery adapters.
abstract class PortalDiscovery {
  ProviderKind get kind;

  Future<DiscoveryResult> discover(
    String userInput, {
    DiscoveryOptions options = DiscoveryOptions.defaults,
  });
}
