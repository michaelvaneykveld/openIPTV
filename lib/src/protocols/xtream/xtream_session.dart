import 'xtream_login_models.dart';
import 'xtream_portal_configuration.dart';

/// Immutable representation of an authenticated Xtream session.
///
/// Unlike Stalker, Xtream does not issue a bearer token; instead the API
/// expects the username/password pair on every request. We still capture
/// the session after a successful login so we can carry along metadata such
/// as server time offsets and stream URL helpers.
class XtreamSession {
  final XtreamPortalConfiguration configuration;
  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;
  final DateTime establishedAt;

  XtreamSession({
    required this.configuration,
    required this.userInfo,
    required this.serverInfo,
    required this.establishedAt,
  });

  /// Base query parameters that must accompany most Xtream endpoints.
  Map<String, String> get credentialQuery => {
        'username': configuration.username,
        'password': configuration.password,
      };

  /// Duration between the device clock and the portal's clock. Useful when
  /// trimming EPG windows or aligning catch-up playback (per docs/notes/REWRITE.md).
  Duration? get serverTimeOffset {
    final server = serverInfo.serverTime;
    if (server == null) {
      return null;
    }
    final now = DateTime.now().toUtc();
    return server.difference(now);
  }

  /// Indicates whether the portal considers the account expired.
  bool get isExpired {
    final expiry = userInfo.expiresAt;
    if (expiry == null) {
      return false;
    }
    return DateTime.now().toUtc().isAfter(expiry);
  }

  /// Builds a stream URL for playback, mimicking the helper methods found in
  /// `@iptv/xtream-api`. We keep it simple for now: `/live/<user>/<pass>/<id>.ts`.
  Uri buildLiveStreamUri(String streamId, {String extension = 'ts'}) {
    final base = configuration.baseUri;
    final path = 'live/${configuration.username}/${configuration.password}/$streamId.$extension';
    return base.resolve(path);
  }

  /// Builds a VOD URL using the `movie` pattern.
  Uri buildVodStreamUri(String streamId, {String extension = 'mp4'}) {
    final base = configuration.baseUri;
    final path = 'movie/${configuration.username}/${configuration.password}/$streamId.$extension';
    return base.resolve(path);
  }

  /// Builds a series episode URL using the `series` path.
  Uri buildSeriesStreamUri(String streamId, {String extension = 'ts'}) {
    final base = configuration.baseUri;
    final path = 'series/${configuration.username}/${configuration.password}/$streamId.$extension';
    return base.resolve(path);
  }
}
