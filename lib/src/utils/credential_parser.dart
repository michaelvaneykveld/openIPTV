class StalkerCredential {
  final String url;
  final String mac;

  StalkerCredential({required this.url, required this.mac});

  @override
  String toString() => 'Stalker(url: $url, mac: $mac)';
}

class XtreamCredential {
  final String url;
  final String username;
  final String password;

  XtreamCredential({
    required this.url,
    required this.username,
    required this.password,
  });

  @override
  String toString() => 'Xtream(url: $url, user: $username, pass: $password)';
}

class ParsedCredentials {
  final List<StalkerCredential> stalker;
  final List<XtreamCredential> xtream;

  ParsedCredentials({this.stalker = const [], this.xtream = const []});

  bool get isEmpty => stalker.isEmpty && xtream.isEmpty;

  @override
  String toString() =>
      'ParsedCredentials(stalker: ${stalker.length}, xtream: ${xtream.length})';
}

class CredentialParser {
  static final RegExp _macRegex = RegExp(
    r'(?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2})',
    caseSensitive: false,
  );

  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/[^\s]+',
    caseSensitive: false,
  );

  static final RegExp _xtreamUrlWithCredsRegex = RegExp(
    r'(https?:\/\/[^\s]+)\/get\.php\?username=([^\s&]+)&password=([^\s&]+)',
    caseSensitive: false,
  );

  static ParsedCredentials parse(String message) {
    final stalkerCreds = _parseStalker(message);
    final xtreamCreds = _parseXtream(message);
    return ParsedCredentials(stalker: stalkerCreds, xtream: xtreamCreds);
  }

  static List<StalkerCredential> _parseStalker(String message) {
    final List<StalkerCredential> credentials = [];
    String? currentUrl;

    // Split by lines to maintain context
    final lines = message.split('\n');

    for (final line in lines) {
      // Look for URL
      final urlMatch = _urlRegex.firstMatch(line);
      if (urlMatch != null) {
        String foundUrl = urlMatch.group(0)!;
        // Simple heuristic: Stalker URLs often don't have query parameters like get.php
        if (!foundUrl.contains('get.php')) {
          // Clean up URL (remove trailing characters if any)
          foundUrl = foundUrl.replaceAll(RegExp(r'[,\s]+$'), '');
          currentUrl = foundUrl;
        }
      }

      // Look for MAC
      final macMatch = _macRegex.firstMatch(line);
      if (macMatch != null && currentUrl != null) {
        credentials.add(
          StalkerCredential(
            url: currentUrl,
            mac: macMatch.group(0)!.toUpperCase(),
          ),
        );
      }
    }
    return credentials;
  }

  static List<XtreamCredential> _parseXtream(String message) {
    final List<XtreamCredential> credentials = [];

    // 1. Check for full get.php URLs first (strongest signal)
    final fullUrlMatches = _xtreamUrlWithCredsRegex.allMatches(message);
    for (final match in fullUrlMatches) {
      // Extract base URL (remove /get.php...)
      final String baseUrl = match.group(1)!;
      final String user = match.group(2)!;
      final String pass = match.group(3)!;

      credentials.add(
        XtreamCredential(url: baseUrl, username: user, password: pass),
      );
    }

    // 2. Check for separate fields (URL ... User ... Pass)
    // We use a state machine approach on lines
    String? currentUrl;
    String? currentUser;
    String? currentPass;

    final lines = message.split('\n');

    // Regex for user/pass fields
    // Use \b to ensure we don't match inside words (like http matching p:)
    final userRegex = RegExp(
      r'\b(?:username|user|u)\s*[:=]\s*([^\s]+)',
      caseSensitive: false,
    );
    final passRegex = RegExp(
      r'\b(?:password|pass|p)\s*[:=]\s*([^\s]+)',
      caseSensitive: false,
    );

    for (final line in lines) {
      // If we find a full get.php link, we ignore it here as it was handled above
      if (_xtreamUrlWithCredsRegex.hasMatch(line)) continue;

      // Look for potential base URL
      final urlMatch = _urlRegex.firstMatch(line);
      if (urlMatch != null) {
        final String foundUrl = urlMatch.group(0)!;
        if (!foundUrl.contains('get.php')) {
          // If we have a pending credential that is incomplete, we might discard it or keep it?
          // Usually a new URL means a new block.
          currentUrl = foundUrl;
          currentUser = null;
          currentPass = null;
        }
      }

      // Look for User
      final userMatch = userRegex.firstMatch(line);
      if (userMatch != null) {
        currentUser = userMatch.group(1);
      }

      // Look for Pass
      final passMatch = passRegex.firstMatch(line);
      if (passMatch != null) {
        currentPass = passMatch.group(1);
      }

      // If we have all three, add and reset user/pass (keep URL as it might be valid for multiple accounts)
      if (currentUrl != null && currentUser != null && currentPass != null) {
        // Avoid duplicates if this was already caught by the full URL regex
        // (Though we skipped lines with get.php, so it should be safe)
        credentials.add(
          XtreamCredential(
            url: currentUrl,
            username: currentUser,
            password: currentPass,
          ),
        );
        // Reset user/pass to avoid reusing them for the next line unless explicitly found again
        currentUser = null;
        currentPass = null;
      }
    }

    return credentials;
  }
}
