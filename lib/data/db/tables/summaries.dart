part of '../openiptv_db.dart';

@DataClassName('SummaryRecord')
class Summaries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get providerId =>
      integer().references(Providers, #id, onDelete: KeyAction.cascade)();

  TextColumn get kind => textEnum<CategoryKind>()();

  IntColumn get totalItems =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {providerId, kind}
      ];

}
