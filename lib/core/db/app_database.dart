import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Prayers,
    Tags,
    PrayerTags,
    PrayerVerses,
    PrayerEvents,
    CustomVerses,
    SyncTombstones,
    SyncSnapshots,
    AppSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(customVerses);
      }
      if (from < 3) {
        await m.addColumn(prayers, prayers.person);
      }
      if (from < 4) {
        await m.addColumn(prayers, prayers.syncId);
        await m.addColumn(prayers, prayers.shared);
        await m.addColumn(prayers, prayers.authorEmail);
        await m.createTable(syncTombstones);
        await m.createTable(syncSnapshots);
      }
      if (from < 5) {
        await m.createTable(appSessions);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'selah.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
