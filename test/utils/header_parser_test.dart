import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/src/utils/header_parser.dart';

void main() {
  group('parseHeaderInput', () {
    test('returns empty headers when input is blank', () {
      final result = parseHeaderInput('   ');

      expect(result.headers, isEmpty);
      expect(result.error, isNull);
    });

    test('parses multi-line headers with trimming and CRLF support', () {
      final raw = 'User-Agent: CustomClient\r\nX-Token: abc123\nExtra : value';

      final result = parseHeaderInput(raw);

      expect(result.error, isNull);
      expect(result.headers, {
        'User-Agent': 'CustomClient',
        'X-Token': 'abc123',
        'Extra': 'value',
      });
    });

    test('reports an error when a line is missing a colon', () {
      final result = parseHeaderInput('Invalid header line');

      expect(result.headers, isEmpty);
      expect(result.error, 'Headers must use the format "Key: Value".');
    });

    test('reports an error when the header name is empty', () {
      final result = parseHeaderInput(': value');

      expect(result.headers, isEmpty);
      expect(result.error, 'Header names cannot be empty.');
    });
  });
}
