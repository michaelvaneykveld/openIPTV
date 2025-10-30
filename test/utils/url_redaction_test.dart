import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/utils/url_redaction.dart';

void main() {
  group('redactSensitiveUri', () {
    test('removes credentials from query and user info', () {
      final uri = Uri.parse(
        'https://alice:secret@example.com/player_api.php?username=alice&password=pass&type=m3u',
      );

      final sanitized = redactSensitiveUri(uri);

      expect(
        sanitized.toString(),
        'https://example.com/player_api.php?type=m3u',
      );
    });

    test('masks sensitive path segments', () {
      final uri = Uri.parse('https://example.com/token/abcdef12345/channel');

      final sanitized = redactSensitiveUri(uri);

      expect(sanitized.path, '/***/***/channel');
    });

    test('retains non-sensitive query parameters when allowed', () {
      final uri = Uri.parse(
        'https://example.com/list.m3u8?format=json&type=m3u',
      );

      final sanitized = redactSensitiveUri(uri);

      expect(
        sanitized.toString(),
        'https://example.com/list.m3u8?format=json&type=m3u',
      );
    });

    test('drops entire query when requested', () {
      final uri = Uri.parse(
        'https://example.com/list.m3u8?format=json&type=m3u',
      );

      final sanitized = redactSensitiveUri(uri, dropAllQuery: true);

      expect(sanitized.toString(), 'https://example.com/list.m3u8');
    });
  });

  group('redactSensitiveText', () {
    test('replaces credential-like key/value pairs', () {
      final input = 'username=alice&password=secret&token=abcdef';

      final sanitized = redactSensitiveText(input);

      expect(sanitized, 'username=***&password=***&token=***');
    });

    test('handles colon separated patterns', () {
      final input = 'Password: hunter2';

      final sanitized = redactSensitiveText(input);

      expect(sanitized, 'Password:***');
    });
  });

  group('describeDioError', () {
    test('redacts sensitive details from DioException output', () {
      final options = RequestOptions(
        path:
            'https://example.com/player_api.php?username=alice&password=secret',
      );
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: 403,
      );
      final exception = DioException(
        requestOptions: options,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'password=supersecret',
      );

      final description = describeDioError(exception);

      expect(description, contains('https://example.com/player_api.php'));
      expect(description, contains('status=403'));
      expect(description, isNot(contains('alice')));
      expect(description, isNot(contains('secret')));
      expect(description, contains('password=***'));
    });
  });
}
