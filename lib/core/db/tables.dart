import 'package:drift/drift.dart';

@DataClassName('PrayerRow')
class Prayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get request => text()();
  BoolColumn get isAnswered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get answeredAt => dateTime().nullable()();
  TextColumn get answeredNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 40).unique()();
}

class PrayerTags extends Table {
  IntColumn get prayerId =>
      integer().references(Prayers, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {prayerId, tagId};
}

class PrayerVerses extends Table {
  IntColumn get prayerId =>
      integer().references(Prayers, #id, onDelete: KeyAction.cascade)();
  TextColumn get verseId => text()();
  DateTimeColumn get selectedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {prayerId, verseId};
}

class PrayerEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prayerId =>
      integer().references(Prayers, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  DateTimeColumn get at => dateTime()();
}
