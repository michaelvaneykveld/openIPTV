// Xtream Validator - TiviMate style server diagnostics
// Standalone validation for Xtream Codes API servers
// Tests authentication, encoding rules, header requirements, and content delivery

import 'dart:convert';
import 'package:http/http.dart' as http;

class XtreamValidationResult {
  final bool apiOk;
  final bool loginOk;
  final bool liveOk;
  final bool vodOk;
  final bool uaRequired;
  final bool proxyRequired;
  final bool rawColonsAllowed;
  final bool encodedColonsAllowed;
  final Map<String, dynamic> details;
  final String report;

  XtreamValidationResult({
    required this.apiOk,
    required this.loginOk,
    required this.liveOk,
    required this.vodOk,
    required this.uaRequired,
    required this.proxyRequired,
    required this.rawColonsAllowed,
    required this.encodedColonsAllowed,
    required this.details,
    required this.report,
  });

  @override
  String toString() => report;
}

class XtreamValidator {
  final String host;
  final int port;
  final String username;
  final String password;

  XtreamValidator({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  String _buildUrl(String path) => 'http://$host:$port/$path';

  Future<http.Response?> _try(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      return null;
    }
  }

  bool _isVideoContent(http.Response? response) {
    if (response == null) return false;
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    return contentType.contains('video') ||
        contentType.contains('application/octet-stream') ||
        contentType.contains('mpeg');
  }

  bool _isHtmlContent(http.Response? response) {
    if (response == null) return false;
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    return contentType.contains('text/html');
  }

  Future<XtreamValidationResult> validate() async {
    final buffer = StringBuffer();
    final details = <String, dynamic>{};

    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('         XTREAM CODES VALIDATION REPORT');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('Server: $host:$port');
    buffer.writeln('Username: $username');
    buffer.writeln(
      'Password: ${password.length > 4 ? password.substring(0, 4) : password}***',
    );
    buffer.writeln('═══════════════════════════════════════════════════\n');

    // Step 1: API Authentication Check
    buffer.writeln('STEP 1: API Authentication');
    buffer.writeln('───────────────────────────────────────────────────');
    final apiUrl = _buildUrl(
      'player_api.php?username=$username&password=$password',
    );
    buffer.writeln('Testing: $apiUrl');

    final apiResponse = await _try(apiUrl);
    final apiOk =
        apiResponse != null &&
        apiResponse.statusCode == 200 &&
        apiResponse.body.contains('user_info');

    buffer.writeln(
      'Status Code: ${apiResponse?.statusCode ?? "TIMEOUT/ERROR"}',
    );
    buffer.writeln('Result: ${apiOk ? "✓ API OK" : "✗ API FAILED"}\n');

    details['api_status'] = apiResponse?.statusCode;
    details['api_ok'] = apiOk;

    // Step 2: Login Auth Check
    bool loginOk = false;
    if (apiOk) {
      try {
        final apiData = jsonDecode(apiResponse.body);
        loginOk = apiData['user_info']?['auth'] == 1;
        buffer.writeln('STEP 2: Login Authorization');
        buffer.writeln('───────────────────────────────────────────────────');
        buffer.writeln(
          'Auth Status: ${loginOk ? "✓ AUTHENTICATED" : "✗ NOT AUTHORIZED"}\n',
        );
        details['user_info'] = apiData['user_info'];
      } catch (e) {
        buffer.writeln('STEP 2: Login Authorization');
        buffer.writeln('───────────────────────────────────────────────────');
        buffer.writeln('✗ Failed to parse API response\n');
      }
    } else {
      buffer.writeln('STEP 2: Login Authorization');
      buffer.writeln('───────────────────────────────────────────────────');
      buffer.writeln('✗ SKIPPED (API check failed)\n');
    }

    // Step 3: Test Colon Encoding Rules
    buffer.writeln('STEP 3: Colon Encoding Detection');
    buffer.writeln('───────────────────────────────────────────────────');

    // Use real stream IDs: 202076 for live, 193177 for VOD
    final liveTestRaw = _buildUrl('live/$username/$password/202076.ts');
    final liveTestEncoded = _buildUrl(
      'live/${Uri.encodeComponent(username)}/${Uri.encodeComponent(password)}/202076.ts',
    );

    buffer.writeln('Testing RAW: $liveTestRaw');
    final rawResponse = await _try(liveTestRaw);
    final rawColonsAllowed =
        rawResponse != null &&
        (rawResponse.statusCode == 200 || rawResponse.statusCode == 206);

    buffer.writeln('RAW Status: ${rawResponse?.statusCode ?? "TIMEOUT"}');
    buffer.writeln('RAW Result: ${rawColonsAllowed ? "✓ WORKS" : "✗ FAILS"}');

    buffer.writeln('\nTesting ENCODED: $liveTestEncoded');
    final encodedResponse = await _try(liveTestEncoded);
    final encodedColonsAllowed =
        encodedResponse != null &&
        (encodedResponse.statusCode == 200 ||
            encodedResponse.statusCode == 206);

    buffer.writeln(
      'ENCODED Status: ${encodedResponse?.statusCode ?? "TIMEOUT"}',
    );
    buffer.writeln(
      'ENCODED Result: ${encodedColonsAllowed ? "✓ WORKS" : "✗ FAILS"}\n',
    );

    details['raw_colons_allowed'] = rawColonsAllowed;
    details['encoded_colons_allowed'] = encodedColonsAllowed;

    // Step 4: Header Requirements Detection
    buffer.writeln('STEP 4: Header Requirements Detection');
    buffer.writeln('───────────────────────────────────────────────────');

    final uaOnly = {'User-Agent': 'okhttp/4.9.3'};
    final fullHeaders = {
      'User-Agent': 'okhttp/4.9.3',
      'Connection': 'keep-alive',
    };

    final withUA = await _try(liveTestRaw, headers: uaOnly);
    final withFullHeaders = await _try(liveTestRaw, headers: fullHeaders);

    buffer.writeln('Without Headers: ${rawResponse?.statusCode ?? "TIMEOUT"}');
    buffer.writeln('With UA only: ${withUA?.statusCode ?? "TIMEOUT"}');
    buffer.writeln(
      'With UA+Connection: ${withFullHeaders?.statusCode ?? "TIMEOUT"}',
    );

    final uaRequired =
        withFullHeaders != null &&
        (withFullHeaders.statusCode == 200 ||
            withFullHeaders.statusCode == 206) &&
        (rawResponse == null ||
            rawResponse.statusCode == 406 ||
            rawResponse.statusCode == 403);

    buffer.writeln('Headers Required: ${uaRequired ? "✓ YES" : "✗ NO"}\n');

    details['ua_required'] = uaRequired;

    // Step 5: Live Stream Content Validation
    buffer.writeln('STEP 5: Live Stream Content Validation');
    buffer.writeln('───────────────────────────────────────────────────');

    final liveResponse = rawColonsAllowed ? rawResponse : encodedResponse;
    final liveOk =
        liveResponse != null &&
        (liveResponse.statusCode == 200 || liveResponse.statusCode == 206) &&
        _isVideoContent(liveResponse);

    buffer.writeln('Status: ${liveResponse?.statusCode ?? "TIMEOUT"}');
    buffer.writeln(
      'Content-Type: ${liveResponse?.headers['content-type'] ?? "UNKNOWN"}',
    );
    buffer.writeln('Is Video: ${_isVideoContent(liveResponse) ? "YES" : "NO"}');
    buffer.writeln('Result: ${liveOk ? "✓ LIVE OK" : "✗ LIVE FAILED"}\n');

    details['live_ok'] = liveOk;
    details['live_content_type'] = liveResponse?.headers['content-type'];

    // Step 6: VOD Test
    buffer.writeln('STEP 6: VOD Stream Validation');
    buffer.writeln('───────────────────────────────────────────────────');

    final vodUrl = rawColonsAllowed
        ? _buildUrl('movie/$username/$password/193177.mp4')
        : _buildUrl(
            'movie/${Uri.encodeComponent(username)}/${Uri.encodeComponent(password)}/193177.mp4',
          );

    buffer.writeln('Testing: $vodUrl');
    final vodResponse = await _try(
      vodUrl,
      headers: uaRequired ? fullHeaders : null,
    );
    final vodOk =
        vodResponse != null &&
        (vodResponse.statusCode == 200 || vodResponse.statusCode == 206) &&
        _isVideoContent(vodResponse);

    buffer.writeln('Status: ${vodResponse?.statusCode ?? "TIMEOUT"}');
    buffer.writeln(
      'Content-Type: ${vodResponse?.headers['content-type'] ?? "UNKNOWN"}',
    );
    buffer.writeln('Is Video: ${_isVideoContent(vodResponse) ? "YES" : "NO"}');
    buffer.writeln('Result: ${vodOk ? "✓ VOD OK" : "✗ VOD FAILED"}\n');

    details['vod_ok'] = vodOk;
    details['vod_content_type'] = vodResponse?.headers['content-type'];

    // Step 7: Direct Access Check
    buffer.writeln('STEP 7: Direct Access Check');
    buffer.writeln('───────────────────────────────────────────────────');

    final proxyRequired =
        _isHtmlContent(liveResponse) ||
        (liveResponse != null &&
            liveResponse.statusCode == 403 &&
            _isHtmlContent(liveResponse));

    buffer.writeln(
      'HTML Response: ${_isHtmlContent(liveResponse) ? "YES" : "NO"}',
    );
    buffer.writeln(
      'Direct Access Blocked: ${proxyRequired ? "✓ YES" : "✗ NO"}\n',
    );

    details['proxy_required'] = proxyRequired;

    // Summary
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('                     SUMMARY');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('API Check:           ${apiOk ? "✓" : "✗"}');
    buffer.writeln('Login Auth:          ${loginOk ? "✓" : "✗"}');
    buffer.writeln('Live Streaming:      ${liveOk ? "✓" : "✗"}');
    buffer.writeln('VOD Streaming:       ${vodOk ? "✓" : "✗"}');
    buffer.writeln('RAW Colons:          ${rawColonsAllowed ? "✓" : "✗"}');
    buffer.writeln('Encoded Colons:      ${encodedColonsAllowed ? "✓" : "✗"}');
    buffer.writeln('User-Agent Needed:   ${uaRequired ? "✓" : "✗"}');
    buffer.writeln('Direct Access Blocked: ${proxyRequired ? "✓" : "✗"}');
    buffer.writeln('═══════════════════════════════════════════════════');

    return XtreamValidationResult(
      apiOk: apiOk,
      loginOk: loginOk,
      liveOk: liveOk,
      vodOk: vodOk,
      uaRequired: uaRequired,
      proxyRequired: proxyRequired,
      rawColonsAllowed: rawColonsAllowed,
      encodedColonsAllowed: encodedColonsAllowed,
      details: details,
      report: buffer.toString(),
    );
  }
}
