import 'dart:convert';

import 'stalker_handshake_models.dart';
import 'stalker_http_client.dart';
import 'stalker_portal_configuration.dart';
import 'stalker_session.dart';

/// Contract describing how an authenticator should behave. Introducing an
/// interface here allows us to swap implementations (e.g. mock authenticators
/// for tests, or an alternative HTTP stack for desktop builds) without
/// rewriting the surrounding application code.
abstract class StalkerAuthenticator {
  /// Performs the handshake/login flow and returns a fully formed session.
  Future<StalkerSession> authenticate(StalkerPortalConfiguration configuration);
}

/// Default authenticator that uses the `StalkerHttpClient` wrapper and follows
/// the flow documented in REWRITE.md (handshake -> token -> profile probe).
class DefaultStalkerAuthenticator implements StalkerAuthenticator {
  final StalkerHttpClient _httpClient;

  /// Accepts an optional client so callers can inject a mocked Dio instance
  /// or apply additional interceptors without modifying this class.
  DefaultStalkerAuthenticator({StalkerHttpClient? httpClient})
    : _httpClient = httpClient ?? StalkerHttpClient();

  @override
  Future<StalkerSession> authenticate(
    StalkerPortalConfiguration configuration,
  ) async {
    // Compose the handshake request headers and query parameters.
    final handshakeHeaders = _buildHandshakeHeaders(configuration);
    final handshakeQuery = _buildHandshakeQuery(configuration);

    // Execute the handshake against the portal.
    final handshakeResponse = await _httpClient.getPortal(
      configuration,
      queryParameters: handshakeQuery,
      headers: handshakeHeaders,
    );

    // Parse the handshake payload and build a session skeleton.
    final handshakePayload = StalkerHandshakePayload.parse(
      handshakeResponse.body,
    );

    if (_hasHandshakeError(handshakePayload)) {
      throw StalkerAuthenticationException(
        'Portal reported an error during handshake: '
        '${handshakePayload.rawMetadata['error']}',
      );
    }

    // Derive token TTL if the portal reported one.
    final tokenTtl = handshakePayload.tokenTtlSeconds != null
        ? Duration(seconds: handshakePayload.tokenTtlSeconds!)
        : null;

    // Create the session object containing headers, cookies, and metadata.
    final session = StalkerSession(
      configuration: configuration,
      token: handshakePayload.token,
      establishedAt: DateTime.now().toUtc(),
      tokenTtl: tokenTtl,
      rawCookies: handshakeResponse.cookies,
      persistentHeaders: {
        'X-User-Agent': configuration.userAgent,
        'Accept': 'application/json',
        'Connection': 'Keep-Alive',
        ...configuration.extraHeaders,
      },
    );

    // Trigger a profile request to validate that the token and cookies are
    // accepted by the portal. This mirrors the flow in `stalkerhek`.
    await _probeProfile(configuration, session);

    return session;
  }

  /// Builds headers required for the handshake request.
  Map<String, String> _buildHandshakeHeaders(
    StalkerPortalConfiguration configuration,
  ) {
    // Start with headers that identify the client as an Infomir STB.
    final headers = <String, String>{
      'User-Agent': configuration.userAgent,
      'X-User-Agent': configuration.userAgent,
      'Referer': configuration.refererUri.toString(),
      'Accept': 'application/json',
      'Connection': 'Keep-Alive',
      'Accept-Encoding': 'gzip, deflate',
    };

    // Compose the cookie string containing MAC, language, and timezone.
    final cookies = [
      'mac=${configuration.macAddress.toLowerCase()}',
      'stb_lang=${configuration.languageCode}',
      'timezone=${configuration.timezone}',
    ];
    headers['Cookie'] = cookies.join('; ');

    headers.addAll(configuration.extraHeaders);

    return headers;
  }

  /// Constructs the query parameters used during the handshake call.
  Map<String, dynamic> _buildHandshakeQuery(
    StalkerPortalConfiguration configuration,
  ) {
    return <String, dynamic>{
      'type': 'stb',
      'action': 'handshake',
      'token': '',
      'prehash': '',
      'device_id': configuration.macAddress.toLowerCase(),
      'device_id2': configuration.macAddress.toLowerCase(),
      'mac': configuration.macAddress.toLowerCase(),
      'JsHttpRequest': '1-xml',
    };
  }

  /// Sends a profile request using the freshly created session. This ensures
  /// the token/cookie combo is accepted and surfaces portal-side errors early.
  Future<void> _probeProfile(
    StalkerPortalConfiguration configuration,
    StalkerSession session,
  ) async {
    // Build query parameters expected by the profile endpoint.
    final profileQuery = <String, dynamic>{
      'type': 'stb',
      'action': 'get_profile',
      'token': session.token,
      'mac': configuration.macAddress.toLowerCase(),
      'JsHttpRequest': '1-xml',
    };

    // Reuse the session to create the authenticated headers.
    final profileHeaders = session.buildAuthenticatedHeaders();

    final response = await _httpClient.getPortal(
      configuration,
      queryParameters: profileQuery,
      headers: profileHeaders,
    );

    _validateProfileResponse(response);
  }

  /// Checks the profile response body for the success marker used by most
  /// portals. Throws an exception when the portal indicates failure.
  void _validateProfileResponse(PortalResponseEnvelope envelope) {
    if (envelope.statusCode >= 400) {
      throw StalkerAuthenticationException(
        'Profile probe failed with HTTP status ${envelope.statusCode}.',
      );
    }

    // Attempt to decode JSON so we can inspect the `js` section.
    final dynamic decoded = envelope.body is String
        ? jsonDecode(envelope.body)
        : envelope.body;

    if (decoded is! Map<String, dynamic>) {
      throw const StalkerAuthenticationException(
        'Profile probe returned an unexpected payload format.',
      );
    }

    final jsonSection = decoded['js'];
    if (jsonSection is Map<String, dynamic>) {
      final error = jsonSection['error'];
      if (error is String && error.isNotEmpty && error != '0') {
        throw StalkerAuthenticationException(
          'Portal rejected the session: $error',
        );
      }
      final result = jsonSection['result'];
      if (result is bool && result == false) {
        throw const StalkerAuthenticationException(
          'Portal reported an unsuccessful profile result.',
        );
      }
    }
  }

  /// Returns true when the handshake response contains an error message.
  bool _hasHandshakeError(StalkerHandshakePayload payload) {
    final errorValue = payload.rawMetadata['error'];
    if (errorValue is String && errorValue.isNotEmpty && errorValue != '0') {
      return true;
    }
    return false;
  }
}

/// Custom exception raised when the authentication flow fails. We keep the
/// message intentionally descriptive so the UI can decide how to present it
/// to the user.
class StalkerAuthenticationException implements Exception {
  final String message;

  const StalkerAuthenticationException(this.message);

  @override
  String toString() => 'StalkerAuthenticationException: $message';
}
