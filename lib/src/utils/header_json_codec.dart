import 'dart:convert';

Map<String, String> decodeHeadersJson(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(raw);
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
