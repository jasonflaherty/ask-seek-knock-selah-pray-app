import '../../prayers/domain/prayer.dart';
import 'sheet_row.dart';

/// Outcome of merging local church prayers with remote sheet rows.
class SheetMergeResult {
  const SheetMergeResult({
    required this.localUpserts,
    required this.localDeletes,
    required this.sheetUpserts,
    required this.sheetDeletes,
    required this.snapshotFingerprints,
  });

  /// Create or update these local prayers from the sheet.
  final List<SheetPrayerRow> localUpserts;

  /// Remove local church prayers with these sync ids.
  final List<String> localDeletes;

  /// Write these rows to the sheet (create or update).
  final List<SheetPrayerRow> sheetUpserts;

  /// Mark these sync ids deleted on the sheet.
  final List<String> sheetDeletes;

  /// Fingerprints to store after a successful sync (active rows only).
  final Map<String, String> snapshotFingerprints;
}

SheetPrayerRow prayerToSheetRow(Prayer prayer) {
  if (prayer.syncId == null || prayer.syncId!.isEmpty) {
    throw ArgumentError('Church prayer requires syncId');
  }
  return SheetPrayerRow(
    syncId: prayer.syncId!,
    authorEmail: prayer.authorEmail,
    name: prayer.name,
    person: prayer.person,
    request: prayer.request,
    tags: List.of(prayer.tags),
    verseIds: List.of(prayer.verseIds),
    isAnswered: prayer.isAnswered,
    answeredNote: prayer.answeredNote,
    updatedAt: prayer.updatedAt,
    deleted: false,
  );
}

/// Three-way merge of church prayers against last-sync snapshots.
///
/// Private prayers must not be passed in [localChurch]. Remote deleted rows
/// and local tombstones drive removals.
SheetMergeResult mergeChurchSheet({
  required List<Prayer> localChurch,
  required List<SheetPrayerRow> remote,
  required Map<String, String> snapshots,
  required List<PendingTombstone> tombstones,
}) {
  final localById = <String, Prayer>{};
  for (final p in localChurch) {
    if (!p.shared) continue;
    final id = p.syncId;
    if (id == null || id.isEmpty) continue;
    localById[id] = p;
  }

  final remoteById = {
    for (final r in remote)
      if (r.syncId.isNotEmpty) r.syncId: r,
  };

  final tombstoneIds = {for (final t in tombstones) t.syncId};

  final localUpserts = <SheetPrayerRow>[];
  final localDeletes = <String>[];
  final sheetUpserts = <SheetPrayerRow>[];
  final sheetDeletes = <String>{};
  final nextSnapshots = <String, String>{};

  final allIds = <String>{
    ...localById.keys,
    ...remoteById.keys,
    ...tombstoneIds,
    ...snapshots.keys,
  };

  for (final syncId in allIds) {
    final local = localById[syncId];
    final remoteRow = remoteById[syncId];
    final baseFp = snapshots[syncId];
    final hasTombstone = tombstoneIds.contains(syncId);

    if (hasTombstone) {
      // Local delete / unshare: push tombstone; drop local if still present.
      sheetDeletes.add(syncId);
      if (local != null) localDeletes.add(syncId);
      // No snapshot for deleted rows.
      continue;
    }

    if (remoteRow != null && remoteRow.deleted) {
      // Sheet tombstone: remove locally; keep sheet deleted.
      if (local != null) localDeletes.add(syncId);
      sheetDeletes.add(syncId);
      continue;
    }

    if (local == null && remoteRow == null) {
      // Stale snapshot only.
      continue;
    }

    if (local == null && remoteRow != null) {
      // New from church sheet.
      localUpserts.add(remoteRow);
      nextSnapshots[syncId] = remoteRow.fingerprint();
      continue;
    }

    if (local != null && remoteRow == null) {
      // Local church prayer not on sheet yet.
      final row = prayerToSheetRow(local);
      sheetUpserts.add(row);
      nextSnapshots[syncId] = row.fingerprint();
      continue;
    }

    // Both present and not deleted.
    final localRow = prayerToSheetRow(local!);
    final remoteFp = remoteRow!.fingerprint();
    final localFp = localRow.fingerprint();

    final localChanged = baseFp == null || localFp != baseFp;
    final remoteChanged = baseFp == null || remoteFp != baseFp;

    if (!localChanged && !remoteChanged) {
      nextSnapshots[syncId] = localFp;
      continue;
    }

    if (localChanged && !remoteChanged) {
      sheetUpserts.add(localRow);
      nextSnapshots[syncId] = localFp;
      continue;
    }

    if (!localChanged && remoteChanged) {
      localUpserts.add(remoteRow);
      nextSnapshots[syncId] = remoteFp;
      continue;
    }

    // Both changed: last-write-wins by updatedAt (strictly newer remote wins).
    if (remoteRow.updatedAt.isAfter(localRow.updatedAt)) {
      localUpserts.add(remoteRow);
      nextSnapshots[syncId] = remoteFp;
    } else {
      sheetUpserts.add(localRow);
      nextSnapshots[syncId] = localFp;
    }
  }

  return SheetMergeResult(
    localUpserts: localUpserts,
    localDeletes: localDeletes,
    sheetUpserts: sheetUpserts,
    sheetDeletes: sheetDeletes.toList(),
    snapshotFingerprints: nextSnapshots,
  );
}
