import 'dart:convert';

/// Represents the minimal JSON payload we care about from the handshake
/// endpoint. The response shape follows the `stalkerhek` reference: a root
/// object with a `js` child that contains the token and optional metadata.
class StalkerHandshakePayload {
  /// Token string granted by the portal.
  final String token;

  /// Optional string echoing the MAC address the portal associated with the
  /// session. Some portals send it back for logging purposes only.
  final String? mac;

  /// Optional numeric value describing the token lifetime in seconds.
  /// Not every deployment sends it, but we expose the field for future use.
  final int? tokenTtlSeconds;

  /// Additional vendor-specific metadata we do not interpret yet but keep
  /// around so we can inspect/debug problematic portals.
  final Map<String, dynamic> rawMetadata;

  /// Constructs the payload object.
  StalkerHandshakePayload({
    required this.token,
    this.mac,
    this.tokenTtlSeconds,
    Map<String, dynamic>? rawMetadata,
  }) : rawMetadata = Map.unmodifiable(rawMetadata ?? const {});

  /// Parses the handshake response. Accepts both JSON strings and already
  /// decoded maps because some HTTP clients perform decoding for us.
  factory StalkerHandshakePayload.parse(dynamic raw) {
    // Convert strings into maps when necessary.
    final dynamic decoded =
        raw is String ? jsonDecode(raw) : raw;

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected handshake payload format: expected a JSON object.',
      );
    }

    final jsSection = decoded['js'];
    if (jsSection is! Map<String, dynamic>) {
      throw const FormatException(
        'Handshake payload missing "js" object produced by the portal.',
      );
    }

    final tokenValue = jsSection['token'];
    if (tokenValue is! String || tokenValue.isEmpty) {
      throw const FormatException(
        'Handshake payload did not contain a token string.',
      );
    }

    // Capture metadata we do not understand yet so we can surface it when
    // debugging troublesome portals.
    final metadata = Map<String, dynamic>.from(jsSection)
      ..remove('token');

    return StalkerHandshakePayload(
      token: tokenValue,
      mac: jsSection['mac'] as String?,
      tokenTtlSeconds: _parseInt(jsSection['token_ttl']),
      rawMetadata: metadata,
    );
  }

  /// Converts arbitrary numeric input into an integer if possible.
  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

