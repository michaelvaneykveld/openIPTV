part of '../openiptv_db.dart';

class VodSearchFts extends Table {
  TextColumn get title => text()();
  TextColumn get overview => text()();
  TextColumn get categoryTokens => text().named('category_tokens')();
  TextColumn get providerId => text().named('provider_id')();
  TextColumn get itemType => text().named('item_type')();
  TextColumn get itemId => text().named('item_id')();
}

