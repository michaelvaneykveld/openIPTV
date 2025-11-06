import 'package:drift/drift.dart';

import '../openiptv_db.dart';

part 'artwork_cache_dao.g.dart';

@DriftAccessor(tables: [ArtworkCache])
class ArtworkCacheDao extends DatabaseAccessor<OpenIptvDb>
    with _$ArtworkCacheDaoMixin {
  ArtworkCacheDao(super.db);

  Future<ArtworkCacheRecord?> findByUrl(String url) {
    final query = select(artworkCache)
      ..where((tbl) => tbl.url.equals(url))
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> upsertEntry({
    required String url,
    String? etag,
    String? hash,
    Uint8List? bytes,
    String? filePath,
    int? byteSize,
    int? width,
    int? height,
    DateTime? expiresAt,
    bool needsRefresh = false,
  }) async {
    final now = DateTime.now().toUtc();

    final updated = await (update(artworkCache)
          ..where((tbl) => tbl.url.equals(url)))
        .write(
      ArtworkCacheCompanion(
        etag: Value(etag),
        hash: Value(hash),
        bytes: Value(bytes),
        filePath: Value(filePath),
        byteSize: Value(byteSize),
        width: Value(width),
        height: Value(height),
        fetchedAt: Value(now),
        lastAccessedAt: Value(now),
        expiresAt: Value(expiresAt),
        needsRefresh: Value(needsRefresh),
      ),
    );

    if (updated > 0) {
      final existing = await findByUrl(url);
      return existing?.id ?? 0;
    }

    return into(artworkCache).insert(
      ArtworkCacheCompanion.insert(
        url: url,
        etag: Value(etag),
        hash: Value(hash),
        bytes: Value(bytes),
        filePath: Value(filePath),
        byteSize: Value(byteSize),
        width: Value(width),
        height: Value(height),
        fetchedAt: now,
        lastAccessedAt: now,
        expiresAt: Value(expiresAt),
        needsRefresh: Value(needsRefresh),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> updateAccessTime(int id) {
    return (update(artworkCache)..where((tbl) => tbl.id.equals(id))).write(
      ArtworkCacheCompanion(
        lastAccessedAt: Value(DateTime.now().toUtc()),
        needsRefresh: const Value(false),
      ),
    );
  }

  Future<int> markForRefresh(String url) {
    return (update(artworkCache)..where((tbl) => tbl.url.equals(url))).write(
      const ArtworkCacheCompanion(
        needsRefresh: Value(true),
      ),
    );
  }

  Future<int> deleteById(int id) {
    return (delete(artworkCache)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteByUrl(String url) {
    return (delete(artworkCache)..where((tbl) => tbl.url.equals(url))).go();
  }

  Future<List<ArtworkCacheRecord>> pruneToEntryBudget(int maxEntries) async {
    final ordered = await (select(artworkCache)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.lastAccessedAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();

    if (maxEntries <= 0) {
      if (ordered.isNotEmpty) {
        await delete(artworkCache).go();
      }
      return ordered;
    }

    if (ordered.length <= maxEntries) {
      return const <ArtworkCacheRecord>[];
    }

    final toRemove = ordered.take(ordered.length - maxEntries).toList();
    final ids = toRemove.map((record) => record.id).toList();
    await (delete(artworkCache)..where((tbl) => tbl.id.isIn(ids))).go();
    return toRemove;
  }

  Future<List<ArtworkCacheRecord>> pruneToSizeBudget(int maxBytes) async {
    if (maxBytes <= 0) {
      final all = await select(artworkCache).get();
      if (all.isNotEmpty) {
        await delete(artworkCache).go();
      }
      return all;
    }

    final ordered = await (select(artworkCache)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.lastAccessedAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
    final totalBytes = ordered.fold<int>(
      0,
      (sum, record) => sum + (record.byteSize ?? 0),
    );
    if (totalBytes <= maxBytes) {
      return const <ArtworkCacheRecord>[];
    }

    var bytes = totalBytes;
    final idsToDelete = <int>[];
    final recordsToDelete = <ArtworkCacheRecord>[];

    for (final record in ordered) {
      if (bytes <= maxBytes) break;
      idsToDelete.add(record.id);
      final size = record.byteSize ?? 0;
      bytes -= size;
      recordsToDelete.add(record);
    }

    if (idsToDelete.isEmpty) {
      return const <ArtworkCacheRecord>[];
    }

    await (delete(artworkCache)..where((tbl) => tbl.id.isIn(idsToDelete))).go();
    return recordsToDelete;
  }
}
