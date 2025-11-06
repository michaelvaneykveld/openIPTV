import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:openiptv/data/db/dao/channel_dao.dart';
import 'package:openiptv/data/db/dao/provider_dao.dart';
import 'package:openiptv/data/db/dao/user_flag_dao.dart';
import 'package:openiptv/data/db/openiptv_db.dart';

void main() {
  late OpenIptvDb db;
  late ProviderDao providerDao;
  late ChannelDao channelDao;
  late UserFlagDao userFlagDao;
  late int providerId;
  late int channelId;

  setUp(() async {
    db = OpenIptvDb.inMemory();
    providerDao = ProviderDao(db);
    channelDao = ChannelDao(db);
    userFlagDao = UserFlagDao(db);

    providerId = await providerDao.createProvider(
      ProvidersCompanion.insert(
        kind: ProviderKind.xtream,
        lockedBase: 'https://demo',
        displayName: const Value('Demo Provider'),
      ),
    );

    channelId = await channelDao.upsertChannel(
      providerId: providerId,
      providerKey: 'stream-1',
      name: 'Demo Channel',
      number: 1,
      isRadio: false,
      logoUrl: null,
      streamUrlTemplate: null,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('setFlags upserts and clears records', () async {
    await userFlagDao.setFlags(
      providerId: providerId,
      channelId: channelId,
      isFavorite: true,
    );

    var record = await userFlagDao.findByChannel(channelId);
    expect(record, isNotNull);
    expect(record!.isFavorite, isTrue);
    expect(record.isHidden, isFalse);

    await userFlagDao.setFlags(
      providerId: providerId,
      channelId: channelId,
      isFavorite: true,
      isHidden: true,
    );

    record = await userFlagDao.findByChannel(channelId);
    expect(record, isNotNull);
    expect(record!.isHidden, isTrue);

    await userFlagDao.setFlags(
      providerId: providerId,
      channelId: channelId,
    );

    record = await userFlagDao.findByChannel(channelId);
    expect(record, isNull);
  });

  test('watchForProvider emits updates', () async {
    final initial = await userFlagDao.watchForProvider(providerId).first;
    expect(initial, isEmpty);

    await userFlagDao.setFlags(
      providerId: providerId,
      channelId: channelId,
      isFavorite: true,
    );

    final next = await userFlagDao.watchForProvider(providerId).first;
    expect(next, hasLength(1));
    expect(next.first.isFavorite, isTrue);
  });
}
