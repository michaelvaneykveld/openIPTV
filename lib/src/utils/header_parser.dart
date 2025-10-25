class HeaderParseResult {
  final Map<String, String> headers;
  final String? error;

  const HeaderParseResult({required this.headers, this.error});

  bool get hasError => error != null;
}

HeaderParseResult parseHeaderInput(String raw) {
  final trimmedBlock = raw.trim();
  if (trimmedBlock.isEmpty) {
    return const HeaderParseResult(headers: {});
  }

  final headers = <String, String>{};
  final lines = trimmedBlock.split(RegExp(r'\r?\n'));
  for (final line in lines) {
    final entry = line.trim();
    if (entry.isEmpty) {
      continue;
    }

    final separatorIndex = entry.indexOf(':');
    if (separatorIndex == -1) {
      return const HeaderParseResult(
        headers: {},
        error: 'Headers must use the format "Key: Value".',
      );
    }

    final key = entry.substring(0, separatorIndex).trim();
    final value = entry.substring(separatorIndex + 1).trim();

    if (key.isEmpty) {
      return const HeaderParseResult(
        headers: {},
        error: 'Header names cannot be empty.',
      );
    }

    headers[key] = value;
  }

  return HeaderParseResult(headers: Map.unmodifiable(headers));
}
