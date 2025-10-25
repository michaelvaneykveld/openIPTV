import 'stalker_portal_configuration.dart';

/// Represents an authenticated session against a Stalker/Ministra portal.
///
/// The session encapsulates the token, cookies, and other derived headers
/// produced by the handshake. Keeping everything in one immutable object
/// allows higher layers to share it with repositories, schedulers, or
/// background workers without worrying about partial state being mutated.
class StalkerSession {
  /// Static portal configuration used to produce the handshake. We retain
  /// it so future requests can easily rebuild referers or MAC cookies.
  final StalkerPortalConfiguration configuration;

  /// Token returned by the handshake sequence (`js.token` in the JSON
  /// payload). This value is echoed in subsequent portal calls via cookies
  /// or headers depending on the endpoint.
  final String token;

  /// Timestamp used to keep track of when the handshake was performed.
  /// Downstream managers can compare it with their expiry policy to decide
  /// whether to trigger a re-handshake.
  final DateTime establishedAt;

  /// Optional TTL reported by the portal. Most installations omit this,
  /// but we expose the field so the future implementation can obey it when
  /// present.
  final Duration? tokenTtl;

  /// Raw `Set-Cookie` values returned by the handshake. They are stored as
  /// individual header strings so we can reconstruct the `Cookie` header
  /// lazily and preserve portal-specific attributes like `path` or flags.
  final List<String> rawCookies;

  /// Additional headers the portal expects to be echoed on each request,
  /// e.g. Infomir-specific `X-User-Agent`. By capturing them here we make
  /// the session agnostic of the HTTP client implementation.
  final Map<String, String> persistentHeaders;

  /// Creates a new session instance.
  StalkerSession({
    required this.configuration,
    required this.token,
    required this.establishedAt,
    this.tokenTtl,
    List<String>? rawCookies,
    Map<String, String>? persistentHeaders,
  })  : rawCookies = List.unmodifiable(rawCookies ?? const []),
        persistentHeaders = Map.unmodifiable(persistentHeaders ?? const {});

  /// Builds the complete cookie header expected by the portal. We merge the
  /// handshake cookies with the mandatory MAC and language cookies described
  /// in the rewrite blueprint.
  String get cookieHeader {
    // Start with cookies required by Infomir STBs so that every request
    // looks authentic even if the server ignored them during the handshake.
    final pieces = <String>[
      'mac=${configuration.macAddress.toLowerCase()}',
      'stb_lang=${configuration.languageCode}',
      'timezone=${configuration.timezone}',
    ];

    // Append any cookies emitted by the server, but strip attributes such
    // as `Path` or `Expires` because the client must only send name=value
    // pairs in the Cookie header.
    for (final raw in rawCookies) {
      final cookieValue = raw.split(';').first.trim();
      if (cookieValue.isNotEmpty) {
        pieces.add(cookieValue);
      }
    }

    // Ensure the handshake token is present even if the server skipped it
    // in Set-Cookie (older portals still expect it under the `token` key).
    if (!pieces.any((entry) => entry.startsWith('token='))) {
      pieces.add('token=$token');
    }

    return pieces.join('; ');
  }

  /// Assembles the base set of headers that should accompany every portal
  /// request once the session is established.  High-level API wrappers can
  /// add endpoint-specific headers on top of this collection.
  Map<String, String> buildAuthenticatedHeaders() {
    // Begin with the persistent headers captured during the handshake.
    final headers = Map<String, String>.from(persistentHeaders);

    // Inject the standard Stalker headers described in the reference code.
    headers.putIfAbsent('User-Agent', () => configuration.userAgent);
    headers.putIfAbsent('X-User-Agent', () => configuration.userAgent);
    headers.putIfAbsent('Referer', () => configuration.refererUri.toString());
    headers.putIfAbsent('Cookie', () => cookieHeader);
    headers.putIfAbsent('Authorization', () => 'Bearer $token');

    return headers;
  }

  /// Helper describing whether the session should be considered stale.
  /// This makes it trivial for higher layers to force a new handshake when
  /// encountering 401/403 responses, as recommended in `REWRITE.md`.
  bool get isExpired {
    if (tokenTtl == null) {
      return false;
    }
    final expiry = establishedAt.add(tokenTtl!);
    return DateTime.now().isAfter(expiry);
  }
}

