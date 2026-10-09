import '../../../core/db/app_database.dart';
import '../domain/sheet_row.dart';

/// Persists sync fingerprints and tombstones for three-way merge.
class SyncSnapshotStore {
  SyncSnapshotStore(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> allSnapshots() async {
    final rows = await _db.select(_db.syncSnapshots).get();
    return {for (final r in rows) r.syncId: r.fingerprint};
  }

  Future<List<PendingTombstone>> allTombstones() async {
    final rows = await _db.select(_db.syncTombstones).get();
    return [
      for (final r in rows)
        PendingTombstone(syncId: r.syncId, deletedAt: r.deletedAt),
    ];
  }

  Future<void> replaceSnapshots(Map<String, String> fingerprints) async {
    await _db.transaction(() async {
      await _db.delete(_db.syncSnapshots).go();
      for (final entry in fingerprints.entries) {
        await _db.into(_db.syncSnapshots).insert(
              SyncSnapshotsCompanion.insert(
                syncId: entry.key,
                fingerprint: entry.value,
              ),
            );
      }
    });
  }

  Future<void> clearTombstones(Iterable<String> syncIds) async {
    final ids = syncIds.toList();
    if (ids.isEmpty) return;
    await (_db.delete(_db.syncTombstones)..where((t) => t.syncId.isIn(ids)))
        .go();
  }

  Future<void> upsertTombstone(String syncId, DateTime deletedAt) async {
    await _db.into(_db.syncTombstones).insertOnConflictUpdate(
          SyncTombstonesCompanion.insert(
            syncId: syncId,
            deletedAt: deletedAt,
          ),
        );
  }
}
