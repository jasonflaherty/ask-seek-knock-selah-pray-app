import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/church_sync/domain/sheet_merge.dart';
import 'package:selah/features/church_sync/domain/sheet_row.dart';
import 'package:selah/features/prayers/domain/prayer.dart';

Prayer _church({
  required String syncId,
  required String name,
  required DateTime updatedAt,
  String request = 'Please pray',
  bool shared = true,
}) {
  return Prayer(
    id: syncId.hashCode.abs(),
    name: name,
    request: request,
    isAnswered: false,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    syncId: syncId,
    shared: shared,
    authorEmail: 'a@example.com',
  );
}

SheetPrayerRow _remote({
  required String syncId,
  required String name,
  required DateTime updatedAt,
  String request = 'Please pray',
  bool deleted = false,
}) {
  return SheetPrayerRow(
    syncId: syncId,
    authorEmail: 'a@example.com',
    name: name,
    request: request,
    updatedAt: updatedAt,
    deleted: deleted,
  );
}

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 2);
  final t2 = DateTime.utc(2026, 1, 3);

  test('private prayers are ignored when not in localChurch list', () {
    final result = mergeChurchSheet(
      localChurch: const [],
      remote: [_remote(syncId: 's1', name: 'Church', updatedAt: t1)],
      snapshots: const {},
      tombstones: const [],
    );
    expect(result.localUpserts, hasLength(1));
    expect(result.localUpserts.first.syncId, 's1');
  });

  test('new local church prayer pushes to sheet', () {
    final local = _church(syncId: 's1', name: 'Heal', updatedAt: t1);
    final result = mergeChurchSheet(
      localChurch: [local],
      remote: const [],
      snapshots: const {},
      tombstones: const [],
    );
    expect(result.sheetUpserts, hasLength(1));
    expect(result.sheetUpserts.first.name, 'Heal');
    expect(result.localUpserts, isEmpty);
  });

  test('only remote changed pulls to local', () {
    final local = _church(syncId: 's1', name: 'Old', updatedAt: t0);
    final remote = _remote(syncId: 's1', name: 'New', updatedAt: t1);
    final base = prayerToSheetRow(local).fingerprint();
    final result = mergeChurchSheet(
      localChurch: [local],
      remote: [remote],
      snapshots: {'s1': base},
      tombstones: const [],
    );
    expect(result.localUpserts, hasLength(1));
    expect(result.localUpserts.first.name, 'New');
    expect(result.sheetUpserts, isEmpty);
  });

  test('only local changed pushes to sheet', () {
    final local = _church(syncId: 's1', name: 'Local', updatedAt: t1);
    final remote = _remote(syncId: 's1', name: 'Old', updatedAt: t0);
    final base = remote.fingerprint();
    final result = mergeChurchSheet(
      localChurch: [local],
      remote: [remote],
      snapshots: {'s1': base},
      tombstones: const [],
    );
    expect(result.sheetUpserts, hasLength(1));
    expect(result.sheetUpserts.first.name, 'Local');
    expect(result.localUpserts, isEmpty);
  });

  test('both changed: newer updatedAt wins', () {
    final local = _church(syncId: 's1', name: 'Phone', updatedAt: t2);
    final remote = _remote(syncId: 's1', name: 'Sheet', updatedAt: t1);
    final stale = _remote(syncId: 's1', name: 'Base', updatedAt: t0);
    final result = mergeChurchSheet(
      localChurch: [local],
      remote: [remote],
      snapshots: {'s1': stale.fingerprint()},
      tombstones: const [],
    );
    expect(result.sheetUpserts.single.name, 'Phone');
    expect(result.localUpserts, isEmpty);

    final remoteNewer = mergeChurchSheet(
      localChurch: [_church(syncId: 's1', name: 'Phone', updatedAt: t1)],
      remote: [_remote(syncId: 's1', name: 'Sheet', updatedAt: t2)],
      snapshots: {'s1': stale.fingerprint()},
      tombstones: const [],
    );
    expect(remoteNewer.localUpserts.single.name, 'Sheet');
  });

  test('local tombstone pushes sheet delete without removing unshared prayer', () {
    final result = mergeChurchSheet(
      localChurch: const [],
      remote: [_remote(syncId: 's1', name: 'X', updatedAt: t1)],
      snapshots: const {},
      tombstones: [PendingTombstone(syncId: 's1', deletedAt: t2)],
    );
    expect(result.sheetDeletes, ['s1']);
    expect(result.localDeletes, isEmpty);
  });

  test('remote deleted removes local church prayer', () {
    final local = _church(syncId: 's1', name: 'X', updatedAt: t1);
    final result = mergeChurchSheet(
      localChurch: [local],
      remote: [_remote(syncId: 's1', name: 'X', updatedAt: t2, deleted: true)],
      snapshots: {'s1': prayerToSheetRow(local).fingerprint()},
      tombstones: const [],
    );
    expect(result.localDeletes, ['s1']);
    expect(result.sheetDeletes, ['s1']);
  });
}
