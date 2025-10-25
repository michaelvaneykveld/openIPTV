import 'm3u_xml_client.dart';
import 'm3u_xml_portal_configuration.dart';
import 'm3u_xml_session.dart';
import 'playlist_fetch_envelope.dart';

/// Contract representing the act of "authenticating" an M3U/XMLTV provider.
///
/// While plain playlists do not require credentials in the traditional sense,
/// we still treat ingestion as an authentication step: verify that the source
/// is reachable, decode the payload, and surface meaningful errors when the
/// playlist is empty or malformed. This keeps the API consistent with the
/// other protocol adapters.
abstract class M3uXmlAuthenticator {
  Future<M3uXmlSession> authenticate(M3uXmlPortalConfiguration configuration);
}

/// Default authenticator that downloads the playlist (and optional XMLTV feed)
/// using the `M3uXmlClient`, performs basic validation, and returns a session
/// ready for parsing or storage.
class DefaultM3uXmlAuthenticator implements M3uXmlAuthenticator {
  final M3uXmlClient _client;

  DefaultM3uXmlAuthenticator({M3uXmlClient? client})
      : _client = client ?? M3uXmlClient();

  @override
  Future<M3uXmlSession> authenticate(
    M3uXmlPortalConfiguration configuration,
  ) async {
    // Fetch the playlist bytes from the configured source.
    final playlistEnvelope = await _client.fetchPlaylist(configuration);

    // Validate that we have a 2xx response (remote sources only). Local files
    // always set `statusCode` to 200 unless the file is missing, in which case
    // `_client` throws before reaching this point.
    if (playlistEnvelope.statusCode >= 400) {
      throw M3uXmlAuthenticationException(
        'Playlist fetch failed with HTTP ${playlistEnvelope.statusCode}.',
      );
    }

    // Decode the playlist text using the preferred encoding and perform a
    // minimal sanity check (presence of #EXTM3U header).
    final playlistText =
        playlistEnvelope.decodeBody(); // uses UTF-8 by default.
    if (!_looksLikeM3u(playlistText)) {
      throw const M3uXmlAuthenticationException(
        'Fetched playlist does not appear to be a valid extended M3U document.',
      );
    }

    // Optionally fetch the XMLTV feed and record metadata.
    PlaylistFetchEnvelope? xmltvEnvelope;
    if (configuration.xmltvSource != null) {
      xmltvEnvelope = await _client.fetchXmltv(configuration);
      if (xmltvEnvelope != null && xmltvEnvelope.statusCode >= 400) {
        throw M3uXmlAuthenticationException(
          'XMLTV fetch failed with HTTP ${xmltvEnvelope.statusCode}.',
        );
      }
      // Attempt to decode early to surface compression issues. We ignore the
      // decoded string because actual parsing will happen later.
      xmltvEnvelope?.decodeBody();
    }

    return M3uXmlSession(
      configuration: configuration,
      playlist: playlistEnvelope,
      xmltv: xmltvEnvelope,
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  /// Performs a quick heuristic to confirm the fetched text is indeed an M3U
  /// playlist. We keep validation intentionally light here; the dedicated
  /// parser module will report detailed syntax errors.
  bool _looksLikeM3u(String content) {
    if (content.trim().isEmpty) {
      return false;
    }
    // The extended M3U spec mandates the `#EXTM3U` header on the first line.
    return content.split('\n').first.trim() == '#EXTM3U';
  }
}

/// Exception thrown when playlist/EPG ingestion fails.
class M3uXmlAuthenticationException implements Exception {
  final String message;

  const M3uXmlAuthenticationException(this.message);

  @override
  String toString() => 'M3uXmlAuthenticationException: $message';
}

