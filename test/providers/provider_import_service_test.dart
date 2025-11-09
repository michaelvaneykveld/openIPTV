import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/import/import_context.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
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

  test('normalizePortalCategoryPayload reads categories key', () {
    final payload = {
      'categories': [
        {'id': 1, 'title': 'Movies'},
        {'id': '2', 'title': 'Series'},
      ],
    };
    final normalized =
        ProviderImportService.normalizePortalCategoryPayload(payload);
    expect(normalized, hasLength(2));
    expect(normalized.first['id'], 1);
    expect(normalized.last['title'], 'Series');
  });

  test('normalizePortalCategoryPayload unwraps nested js data', () {
    final payload = {
      'js': {
        'data': [
          {'category_id': 99, 'title': 'Sports'},
        ],
      },
    };
    final normalized =
        ProviderImportService.normalizePortalCategoryPayload(payload);
    expect(normalized, hasLength(1));
    expect(normalized.single['category_id'], 99);
    expect(normalized.single['title'], 'Sports');
  });

  test('ProviderImportMetricsSummary maps ImportMetrics correctly', () {
    final metrics = ImportMetrics()
      ..channelsUpserted = 5
      ..categoriesUpserted = 3
      ..moviesUpserted = 2
      ..seriesUpserted = 1
      ..seasonsUpserted = 4
      ..episodesUpserted = 8
      ..channelsDeleted = 6
      ..programsUpserted = 10
      ..duration = const Duration(seconds: 2);

    final summary = ProviderImportMetricsSummary.fromMetrics(metrics);
    expect(summary.channelsUpserted, 5);
    expect(summary.categoriesUpserted, 3);
    expect(summary.moviesUpserted, 2);
    expect(summary.seriesUpserted, 1);
    expect(summary.seasonsUpserted, 4);
    expect(summary.episodesUpserted, 8);
    expect(summary.channelsDeleted, 6);
    expect(summary.programsUpserted, 10);
    expect(summary.durationMs, 2000);
  });

  test('ProviderImportEventSerializer round-trips progress events', () {
    const event = ProviderImportProgressEvent(
      providerId: 7,
      kind: ProviderKind.xtream,
      phase: 'fetch',
      metadata: {'count': 3},
    );
    final payload = ProviderImportEventSerializer.serialize(event);
    final decoded = ProviderImportEventSerializer.deserialize(payload);
    expect(decoded, isA<ProviderImportProgressEvent>());
    final progress = decoded! as ProviderImportProgressEvent;
    expect(progress.providerId, 7);
    expect(progress.kind, ProviderKind.xtream);
    expect(progress.phase, 'fetch');
    expect(progress.metadata['count'], 3);
  });

  test('ProviderImportEventSerializer round-trips result events', () {
    final summary = ProviderImportMetricsSummary(
      channelsUpserted: 12,
      durationMs: 1500,
    );
    final event = ProviderImportResultEvent(
      providerId: 9,
      kind: ProviderKind.m3u,
      metrics: summary,
    );
    final payload = ProviderImportEventSerializer.serialize(event);
    final decoded = ProviderImportEventSerializer.deserialize(payload);
    expect(decoded, isA<ProviderImportResultEvent>());
    final result = decoded! as ProviderImportResultEvent;
    expect(result.providerId, 9);
    expect(result.kind, ProviderKind.m3u);
    expect(result.metrics.channelsUpserted, 12);
    expect(result.metrics.durationMs, 1500);
  });
}
