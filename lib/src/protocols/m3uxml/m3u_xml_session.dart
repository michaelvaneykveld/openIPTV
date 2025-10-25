import 'dart:convert';

import 'm3u_xml_portal_configuration.dart';
import 'playlist_fetch_envelope.dart';

/// Captures the result of fetching an M3U playlist (and optional XMLTV feed)
/// for a given portal configuration.
///
/// The session does not parse playlists yet; it simply provides helpers to
/// decode the raw data and to surface metadata for caching decisions. This
/// keeps the future parsing layer focused purely on format semantics.
class M3uXmlSession {
  /// Static configuration that produced this session. Retaining it allows the
  /// caller to schedule refreshes or re-run the fetch when metadata expires.
  final M3uXmlPortalConfiguration configuration;

  /// Raw playlist bytes + metadata.
  final PlaylistFetchEnvelope playlist;

  /// Optional XMLTV feed bytes + metadata.
  final PlaylistFetchEnvelope? xmltv;

  /// Timestamp marking when the fetch completed. Useful for age checks.
  final DateTime fetchedAt;

  M3uXmlSession({
    required this.configuration,
    required this.playlist,
    required this.xmltv,
    required this.fetchedAt,
  });

  /// Returns the playlist text decoded using the configuration's preferred
  /// encoding. Consumers can override the encoding if the provider demands
  /// a different charset.
  String readPlaylist({Encoding? encoding}) {
    return playlist.decodeBody(
      encoding: encoding ?? Encoding.getByName(configuration.preferredEncoding) ?? utf8,
    );
  }

  /// Returns the XMLTV text if available.
  String? readXmltv({Encoding? encoding}) {
    final envelope = xmltv;
    if (envelope == null) {
      return null;
    }
    return envelope.decodeBody(encoding: encoding ?? utf8);
  }

  /// Indicates whether the playlist response hinted at a caching opportunity
  /// (ETag or Last-Modified). Higher layers can persist this metadata for
  /// future conditional GET requests.
  bool get playlistSupportsCacheValidation =>
      playlist.etag != null || playlist.lastModified != null;

  /// Similar indicator for the XMLTV feed.
  bool get xmltvSupportsCacheValidation {
    final envelope = xmltv;
    if (envelope == null) {
      return false;
    }
    return envelope.etag != null || envelope.lastModified != null;
  }
}

