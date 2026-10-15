import 'package:drift/drift.dart';

@DataClassName('PrayerRow')
class Prayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Who this prayer is for (empty = unassigned).
  TextColumn get person =>
      text().withLength(min: 0, max: 100).withDefault(const Constant(''))();
  TextColumn get request => text()();
  BoolColumn get isAnswered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get answeredAt => dateTime().nullable()();
  TextColumn get answeredNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Stable id for group/church sync. Null until first share.
  TextColumn get syncId => text().nullable().unique()();

  /// Legacy flag kept in sync with [shareScope] != justMe.
  BoolColumn get shared => boolean().withDefault(const Constant(false))();

  /// justMe | group | church
  TextColumn get shareScope =>
      text().withLength(min: 1, max: 16).withDefault(const Constant('justMe'))();

  TextColumn get groupId => text().nullable()();
  TextColumn get churchId => text().nullable()();

  /// Account email of the author when shared.
  TextColumn get authorEmail =>
      text().withLength(min: 0, max: 320).withDefault(const Constant(''))();

  TextColumn get authorDisplayName =>
      text().withLength(min: 0, max: 80).withDefault(const Constant(''))();
}

/// Shared prayers deleted locally that still need a server tombstone push.
class SyncTombstones extends Table {
  TextColumn get syncId => text()();
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {syncId};
}

/// Fingerprint of each shared row after the last successful sync.
class SyncSnapshots extends Table {
  TextColumn get syncId => text()();
  TextColumn get fingerprint => text()();

  @override
  Set<Column> get primaryKey => {syncId};
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

/// User-added Scripture used as a prayer argument (promise / answered prayer).
class CustomVerses extends Table {
  TextColumn get id => text()();
  TextColumn get ref => text().withLength(min: 1, max: 80)();

  /// Exact Scripture wording (named `body` so it does not shadow Drift's `text()`).
  TextColumn get body => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached study notes for the person's group.
class StudyNotes extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get authorUserId => text()();
  TextColumn get authorDisplayName =>
      text().withLength(min: 0, max: 80).withDefault(const Constant(''))();
  TextColumn get kind => text().withLength(min: 1, max: 32)();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Time the app was open in the foreground. [endedAt] advances while it is open.
@DataClassName('AppSessionRow')
class AppSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
}
