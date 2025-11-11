MapEntry<String, String>? parseVlcOptHeader(String line) {
  final colonIndex = line.indexOf(':');
  if (colonIndex == -1 || colonIndex == line.length - 1) {
    return null;
  }
  final payload = line.substring(colonIndex + 1);
  final eqIndex = payload.indexOf('=');
  if (eqIndex == -1 || eqIndex == payload.length - 1) {
    return null;
  }
  final option = payload.substring(0, eqIndex).trim().toLowerCase();
  final rawValue = payload.substring(eqIndex + 1).trim();
  if (option.isEmpty || rawValue.isEmpty) {
    return null;
  }

  switch (option) {
    case 'http-user-agent':
      return MapEntry('User-Agent', rawValue);
    case 'http-referrer':
    case 'http-referer':
      return MapEntry('Referer', rawValue);
    case 'http-cookie':
      return MapEntry('Cookie', rawValue);
    case 'http-header':
      final headerSplit = rawValue.indexOf('=');
      if (headerSplit == -1 || headerSplit == rawValue.length - 1) {
        return null;
      }
      final headerKey = rawValue.substring(0, headerSplit).trim();
      final headerValue = rawValue.substring(headerSplit + 1).trim();
      if (headerKey.isEmpty || headerValue.isEmpty) {
        return null;
      }
      return MapEntry(headerKey, headerValue);
    default:
      return null;
  }
}
