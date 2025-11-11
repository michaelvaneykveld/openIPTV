import 'dart:convert';

import 'package:openiptv/src/player/summary_models.dart';

Map<String, String> decodeProfileCustomHeaders(
  ResolvedProviderProfile profile,
) {
  final encoded = profile.secrets['customHeaders'];
  if (encoded == null || encoded.isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
  } catch (_) {
    // Ignore malformed payloads.
  }
  return const {};
}
