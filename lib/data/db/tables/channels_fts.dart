part of '../openiptv_db.dart';

class ChannelSearchFts extends Table {
  TextColumn get name => text()();
  TextColumn get providerKey => text().named('provider_key')();
  TextColumn get categoryTokens => text().named('category_tokens')();
  TextColumn get providerId => text().named('provider_id')();
  TextColumn get channelId => text().named('channel_id')();

  @override
  Set<Column> get primaryKey => {channelId};
}

