import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/src/providers/provider_import_service.dart';

void main() {
  test('parseM3uEntries extracts titles, groups, and radio flags', () {
    const playlist = '''
#EXTM3U
#EXTINF:-1 tvg-name="Movie Night" group-title="Films" tvg-logo="http://logo/movie.png",Movie Night
http://stream.example.com/movie.ts
#EXTGRP:Kids
#EXTINF:-1 radio="true",Kids FM
http://stream.example.com/radio.mp3
''';

    final entries = ProviderImportService.parseM3uEntries(playlist);
    expect(entries, hasLength(2));

    final movie = entries.first;
    expect(movie.name, 'Movie Night');
    expect(movie.group, 'Films');
    expect(movie.logoUrl, 'http://logo/movie.png');
    expect(movie.isRadio, isFalse);
    expect(movie.key, 'http://stream.example.com/movie.ts');

    final radio = entries.last;
    expect(radio.group, 'Kids');
    expect(radio.isRadio, isTrue);
    expect(radio.logoUrl, isNull);
  });

  test('parseM3uEntries falls back to defaults when metadata missing', () {
    const playlist = '''
#EXTM3U
#EXTINF:-1,Plain Entry
http://example.com/plain
''';

    final entries = ProviderImportService.parseM3uEntries(playlist);
    expect(entries, hasLength(1));
    final entry = entries.single;
    expect(entry.group, 'Other');
    expect(entry.name, 'Plain Entry');
    expect(entry.isRadio, isFalse);
  });
}
