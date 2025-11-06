import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/database_key_store.dart';

void main() {
  test('MemoryDatabaseKeyStore generates and reuses key', () async {
    final store = MemoryDatabaseKeyStore();

    final first = await store.obtainOrCreateKey();
    expect(first, isNotEmpty);

    final second = await store.obtainOrCreateKey();
    expect(second, equals(first));

    await store.deleteKey();

    final third = await store.obtainOrCreateKey();
    expect(third, isNotEmpty);
    expect(third, isNot(equals(first)));
  });
}

