import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/artwork_cache_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';

void main() {
  late OpenIptvDb db;
  late ArtworkCacheDao dao;

  setUp(() {
    db = OpenIptvDb.inMemory();
    dao = ArtworkCacheDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert stores and retrieves artwork by url', () async {
    final url = 'https://example.com/logo.png';

    await dao.upsertEntry(
      url: url,
      bytes: Uint8List.fromList([1, 2, 3]),
      byteSize: 3,
      etag: 'W/"123"',
      hash: 'abc',
      expiresAt: DateTime.utc(2024, 01, 01),
    );

    final record = await dao.findByUrl(url);
    expect(record, isNotNull);
    expect(record!.etag, 'W/"123"');
    expect(record.byteSize, 3);
    expect(record.bytes, equals([1, 2, 3]));

    await dao.upsertEntry(
      url: url,
      bytes: Uint8List.fromList([4, 5, 6, 7]),
      byteSize: 4,
      etag: 'W/"456"',
      hash: 'def',
    );

    final updated = await dao.findByUrl(url);
    expect(updated, isNotNull);
    expect(updated!.etag, 'W/"456"');
    expect(updated.byteSize, 4);
    expect(updated.bytes, equals([4, 5, 6, 7]));
  });

  test('pruneToEntryBudget removes least recently used entries', () async {
    for (var i = 0; i < 5; i++) {
      await dao.upsertEntry(
        url: 'https://example.com/logo_$i.png',
        bytes: Uint8List.fromList([i]),
        byteSize: 1,
      );
    }

    final removed = await dao.pruneToEntryBudget(2);
    expect(removed.length, 3);
    for (final record in removed) {
      final stillThere = await dao.findByUrl(record.url);
      expect(stillThere, isNull);
    }

    final remaining = await (db.select(db.artworkCache)).get();
    expect(remaining.length, 2);
  });

  test('pruneToSizeBudget removes entries until within target', () async {
    await dao.upsertEntry(
      url: 'https://example.com/a.png',
      bytes: Uint8List.fromList(List<int>.filled(5, 1)),
      byteSize: 5,
    );
    await dao.upsertEntry(
      url: 'https://example.com/b.png',
      bytes: Uint8List.fromList(List<int>.filled(4, 2)),
      byteSize: 4,
    );
    await dao.upsertEntry(
      url: 'https://example.com/c.png',
      bytes: Uint8List.fromList(List<int>.filled(3, 3)),
      byteSize: 3,
    );

    final removed = await dao.pruneToSizeBudget(6);
    expect(removed.isNotEmpty, isTrue);

    final remainingEntries = await db.select(db.artworkCache).get();
    final remainingBytes = remainingEntries.fold<int>(
      0,
      (sum, record) => sum + (record.byteSize ?? 0),
    );
    expect(remainingBytes <= 6, isTrue);
  });
}
