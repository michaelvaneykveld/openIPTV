import 'package:openiptv/src/utils/url_normalization.dart';

import 'm3u_source_descriptor.dart';
import 'xmltv_source_descriptor.dart';

/// Aggregates the static configuration required to ingest an M3U playlist
/// and its companion XMLTV guide.
///
/// The class intentionally mirrors the philosophy used for Stalker and Xtream:
/// isolate all values that rarely change so higher-level modules can be kept
/// free from URL parsing or header juggling logic.
class M3uXmlPortalConfiguration {
  /// Unique identifier used by the application to map this provider to
  /// database entries and background sync jobs.
  final String portalId;

  /// Optional label displayed in the UI (profile switcher, logs, etc.).
  final String? displayName;

  /// Source descriptor for the M3U playlist (URL or local file).
  final M3uSourceDescriptor m3uSource;

  /// Optional XMLTV source descriptor (URL or local file). Some providers
  /// only expose the playlist, so this field can be null.
  final XmltvSourceDescriptor? xmltvSource;

  /// Optional preferred character encoding when converting playlist bytes
  /// into text. Defaults to UTF-8 which covers the majority of providers.
  final String preferredEncoding;

  /// Optional user-agent override applied to both playlist and XMLTV HTTP
  /// requests. Remote sources can still specify their own headers, but this
  /// value provides a consistent default (e.g. Hypnotix-style UA).
  final String defaultUserAgent;

  /// Whether playlists should allow self-signed TLS certificates.
  final bool allowSelfSignedTls;

  /// Additional headers applied to playlist and XMLTV requests.
  final Map<String, String> defaultHeaders;

  /// Whether HTTP redirects should be followed automatically.
  final bool followRedirects;

  /// Creates a configuration object.
  M3uXmlPortalConfiguration({
    required this.portalId,
    required this.m3uSource,
    this.xmltvSource,
    this.displayName,
    this.preferredEncoding = 'utf-8',
    String? defaultUserAgent,
    this.allowSelfSignedTls = false,
    Map<String, String>? defaultHeaders,
    this.followRedirects = true,
  }) : defaultUserAgent =
           defaultUserAgent ??
           'OpenIPTV/1.0 (+https://github.com/your-org/openiptv)',
       defaultHeaders = defaultHeaders == null
           ? const {}
           : Map.unmodifiable(Map.of(defaultHeaders));

  /// Convenience builder for URL-based playlists. This helps bridge the gap
  /// between the current credential storage and the new modular structure
  /// while the rest of the codebase is being rewritten.
  factory M3uXmlPortalConfiguration.fromUrls({
    required String portalId,
    required String playlistUrl,
    String? xmltvUrl,
    String? displayName,
    Map<String, String>? playlistHeaders,
    Map<String, String>? xmltvHeaders,
    bool allowSelfSignedTls = false,
    Map<String, String>? defaultHeaders,
    String? defaultUserAgent,
    bool followRedirects = true,
  }) {
    final playlistUri = Uri.parse(canonicalizeScheme(playlistUrl));
    final xmltvUri = xmltvUrl != null
        ? Uri.parse(canonicalizeScheme(xmltvUrl))
        : null;

    final mergedHeaders = <String, String>{
      ...?defaultHeaders,
      ...?playlistHeaders,
    };
    final mergedXmltvHeaders = <String, String>{
      ...?defaultHeaders,
      ...?xmltvHeaders,
    };
    return M3uXmlPortalConfiguration(
      portalId: portalId,
      displayName: displayName,
      allowSelfSignedTls: allowSelfSignedTls,
      defaultHeaders: defaultHeaders ?? const {},
      defaultUserAgent: defaultUserAgent,
      followRedirects: followRedirects,
      m3uSource: M3uUrlSource(
        playlistUri: playlistUri,
        headers: mergedHeaders,
        displayName: displayName,
      ),
      xmltvSource: xmltvUrl != null
          ? XmltvUrlSource(
              epgUri: xmltvUri!,
              headers: mergedXmltvHeaders,
              displayName: displayName,
            )
          : null,
    );
  }

  /// Convenience builder for file-based imports.
  factory M3uXmlPortalConfiguration.fromFiles({
    required String portalId,
    required String playlistPath,
    String? xmltvPath,
    String? displayName,
    bool allowSelfSignedTls = false,
    Map<String, String>? defaultHeaders,
    String? defaultUserAgent,
    bool followRedirects = true,
  }) {
    return M3uXmlPortalConfiguration(
      portalId: portalId,
      displayName: displayName,
      allowSelfSignedTls: allowSelfSignedTls,
      defaultHeaders: defaultHeaders ?? const {},
      defaultUserAgent: defaultUserAgent,
      followRedirects: followRedirects,
      m3uSource: M3uFileSource(
        filePath: playlistPath,
        originalFileName: displayName,
        displayName: displayName,
      ),
      xmltvSource: xmltvPath != null
          ? XmltvFileSource(
              filePath: xmltvPath,
              originalFileName: displayName,
              displayName: displayName,
            )
          : null,
    );
  }
}
