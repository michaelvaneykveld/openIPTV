import 'xtream_http_client.dart';
import 'xtream_login_models.dart';
import 'xtream_portal_configuration.dart';
import 'xtream_session.dart';

/// Abstraction describing an Xtream authentication flow. Introducing an
/// interface now keeps the door open for alternative implementations (e.g.
/// caching layers, offline fixtures, or dependency injection in tests).
abstract class XtreamAuthenticator {
  Future<XtreamSession> authenticate(XtreamPortalConfiguration configuration);
}

/// Default authenticator that mirrors the behaviour documented in
/// `@iptv/xtream-api`: call `player_api.php` with just username/password,
/// parse the returned `user_info` + `server_info`, and surface meaningful
/// errors when authentication fails.
class DefaultXtreamAuthenticator implements XtreamAuthenticator {
  final XtreamHttpClient _httpClient;

  DefaultXtreamAuthenticator({XtreamHttpClient? httpClient})
      : _httpClient = httpClient ?? XtreamHttpClient();

  @override
  Future<XtreamSession> authenticate(
    XtreamPortalConfiguration configuration,
  ) async {
    // Fetch the login payload. Xtream uses GET with credentials as query
    // parameters. No extra headers are required beyond User-Agent/Accept.
    final response = await _httpClient.getPlayerApi(configuration);

    if (response.statusCode >= 400) {
      throw XtreamAuthenticationException(
        'Xtream portal responded with HTTP ${response.statusCode} during login.',
      );
    }

    final payload = XtreamLoginPayload.parse(response.body);
    _validate(payload);

    return XtreamSession(
      configuration: configuration,
      userInfo: payload.userInfo,
      serverInfo: payload.serverInfo,
      establishedAt: DateTime.now().toUtc(),
    );
  }

  /// Ensures the login payload indicates a successful authentication.
  void _validate(XtreamLoginPayload payload) {
    if (!payload.userInfo.authenticated) {
      final status = payload.userInfo.status;
      throw XtreamAuthenticationException(
        'Xtream portal rejected credentials (status: $status).',
      );
    }
  }
}

/// Exception thrown when the Xtream login flow fails.
class XtreamAuthenticationException implements Exception {
  final String message;

  const XtreamAuthenticationException(this.message);

  @override
  String toString() => 'XtreamAuthenticationException: $message';
}

