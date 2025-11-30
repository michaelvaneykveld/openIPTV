import 'package:openiptv/src/utils/url_normalization.dart';

/// Static configuration required to connect to a single Xtream Codes portal.
///
/// The aim mirrors the Stalker rewrite: capture immutable connection details
/// in one place so the networking layer can be reused by multiple features
/// (live channels, VOD, EPG) without leaking credential handling through the
/// rest of the application.
class XtreamPortalConfiguration {
  /// Fully qualified base URI (scheme + host + optional port). We normalise
  /// trailing slashes so downstream builders can reliably append API paths.
  final Uri baseUri;

  /// Username supplied by the provider.
  final String username;

  /// Password supplied by the provider.
  final String password;

  /// Optional custom user agent. Some portals block requests that do not
  /// mimic well-known clients (Kodi, Hypnotix) so we give callers control.
  final String userAgent;

  /// The persistent device ID for this installation.
  final String? deviceId;

  /// Whether to trust self-signed TLS certificates for this portal.
  final bool allowSelfSignedTls;

  /// Additional headers sent alongside the standard Xtream headers.
  final Map<String, String> extraHeaders;

  /// Creates a configuration object with pragmatic defaults inspired by the
  /// reference projects highlighted in docs/notes/REWRITE.md.
  XtreamPortalConfiguration({
    required Uri baseUri,
    required this.username,
    required this.password,
    String? userAgent,
    this.deviceId,
    this.allowSelfSignedTls = false,
    Map<String, String>? extraHeaders,
  }) : baseUri = _normaliseBaseUri(baseUri),
       userAgent =
           userAgent ?? 'okhttp/4.9.3', // Standard Android client signature
       extraHeaders = extraHeaders == null
           ? const {}
           : Map.unmodifiable(Map.of(extraHeaders));

  /// Convenience helper used while the rest of the app is being rewritten.
  /// Accepts raw string values (matching the current credential model) and
  /// produces a configuration instance for the protocol layer.
  factory XtreamPortalConfiguration.fromCredentials({
    required String url,
    required String username,
    required String password,
    String? userAgent,
    String? deviceId,
    bool allowSelfSignedTls = false,
    Map<String, String>? extraHeaders,
  }) {
    final canonical = canonicalizeScheme(url);
    return XtreamPortalConfiguration(
      baseUri: Uri.parse(canonical),
      username: username,
      password: password,
      userAgent: userAgent,
      deviceId: deviceId,
      allowSelfSignedTls: allowSelfSignedTls,
      extraHeaders: extraHeaders,
    );
  }

  /// Ensures the base URI never ends with a trailing slash. This keeps future
  /// URL construction deterministic when using Uri.resolve.
  static Uri _normaliseBaseUri(Uri raw) {
    final lowered = raw.replace(
      scheme: raw.scheme.toLowerCase(),
      host: raw.host.toLowerCase(),
    );

    final stripped = stripKnownFiles(
      lowered,
      knownFiles: const {
        'player_api.php',
        'get.php',
        'xmltv.php',
        'portal.php',
        'index.php',
      },
    );

    return ensureTrailingSlash(stripped);
  }
}
