/// Defines the immutable configuration required to talk to a single
/// Stalker/Ministra portal.
///
/// The aim is to decouple low-level request construction from higher level
/// application state. By keeping all static portal properties in one place
/// we can swap different credential sources (secure storage, tests, mock
/// portals) without leaking details into the networking layers.
class StalkerPortalConfiguration {
  /// Fully qualified base URI of the portal. The constructor normalises
  /// missing trailing slashes so later builders can safely append paths.
  final Uri baseUri;

  /// MAC address that identifies the virtual STB during the handshake.
  final String macAddress;

  /// Customisable User-Agent value. Some portals refuse requests unless
  /// the header mimics Infomir STB firmware, so expose it here instead of
  /// hard-coding a string in the HTTP layer.
  final String userAgent;

  /// Value for the `Referer` header when talking to `/portal.php`.
  /// The Enigma2 plugin and `stalkerhek` both send the `/c/` control page,
  /// which we mirror to maximise compatibility.
  final Uri refererUri;

  /// Optional locale hint placed inside cookies (`stb_lang`) during the
  /// handshake. Retained here so future UI settings can change it without
  /// touching the network code.
  final String languageCode;

  /// Optional timezone hint placed inside cookies. Stalker portals use it
  /// when calculating programme guides, so we expose it next to language.
  final String timezone;

  /// Whether the client should accept self-signed TLS certificates when
  /// communicating with the portal.
  final bool allowSelfSignedTls;

  /// Optional extra headers supplied by the user. They are appended to every
  /// request (handshake + authenticated probes) allowing providers that
  /// require bespoke authentication to function.
  final Map<String, String> extraHeaders;

  /// Creates a configuration object. Callers must provide the base URL and
  /// MAC address; other fields fall back to pragmatic defaults used by the
  /// open-source reference clients highlighted in `REWRITE.md`.
  StalkerPortalConfiguration({
    required Uri baseUri,
    required this.macAddress,
    String? userAgent,
    Uri? refererUri,
    this.languageCode = 'en',
    this.timezone = 'UTC',
    this.allowSelfSignedTls = false,
    Map<String, String>? extraHeaders,
  }) : baseUri = _normaliseBaseUri(baseUri),
       userAgent =
           userAgent ??
           'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) InfomirBrowser/3.0 StbApp/0.23',
       refererUri = refererUri ?? _deriveReferer(baseUri),
       extraHeaders = extraHeaders == null
           ? const {}
           : Map.unmodifiable(Map.of(extraHeaders));

  /// Convenience factory to bridge the existing domain model into the new
  /// protocol layer. Keeping the mapping here avoids coupling the protocol
  /// code to repository implementations while we refactor the rest of the
  /// application.
  factory StalkerPortalConfiguration.fromCredentials(
    String portalUrl,
    String mac,
  ) {
    return StalkerPortalConfiguration(
      baseUri: Uri.parse(portalUrl),
      macAddress: mac,
    );
  }

  /// Normalises the base URI by ensuring we always work with the root form
  /// (`https://portal.example.com`) instead of a mix of variants with and
  /// without trailing slashes.
  static Uri _normaliseBaseUri(Uri raw) {
    // Remove trailing slashes because `Uri.resolve` handles path joins
    // deterministically when the base URI ends with the root segment only.
    final cleaned = raw.replace(
      path: raw.path.endsWith('/')
          ? raw.path.substring(0, raw.path.length - 1)
          : raw.path,
    );
    return cleaned;
  }

  /// Builds the default referer URI (portal control page). Stalker servers
  /// check this on some installations, so we follow the community clients.
  static Uri _deriveReferer(Uri rawBase) {
    final normalised = _normaliseBaseUri(rawBase);
    // Append `/c/` just like Infomir set-top boxes so the handshake matches
    // expectations of hardened portal configurations.
    return normalised.resolve('c/');
  }
}
