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

  /// Creates a configuration object with pragmatic defaults inspired by the
  /// reference projects highlighted in `REWRITE.md`.
  XtreamPortalConfiguration({
    required Uri baseUri,
    required this.username,
    required this.password,
    String? userAgent,
  })  : baseUri = _normaliseBaseUri(baseUri),
        userAgent = userAgent ??
            'Hypnotix/2.0 (Linux; IPTV) Flutter/OpenIPTV XtreamAdapter';

  /// Convenience helper used while the rest of the app is being rewritten.
  /// Accepts raw string values (matching the current credential model) and
  /// produces a configuration instance for the protocol layer.
  factory XtreamPortalConfiguration.fromCredentials({
    required String url,
    required String username,
    required String password,
  }) {
    return XtreamPortalConfiguration(
      baseUri: Uri.parse(url),
      username: username,
      password: password,
    );
  }

  /// Ensures the base URI never ends with a trailing slash. This keeps future
  /// URL construction deterministic when using `Uri.resolve`.
  static Uri _normaliseBaseUri(Uri raw) {
    final cleaned =
        raw.replace(path: raw.path.endsWith('/') ? raw.path.substring(0, raw.path.length - 1) : raw.path);
    return cleaned;
  }
}

