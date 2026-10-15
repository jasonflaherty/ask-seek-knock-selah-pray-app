import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/db/app_database.dart';
import 'package:selah/features/metrics/data/drift_usage_repository.dart';

void main() {
  late AppDatabase db;
  late DriftUsageRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = DriftUsageRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('beginSession and markOpenUntil persist foreground time', () async {
    final start = DateTime(2024, 6, 15, 12);
    final id = await repo.beginSession(start);
    final opened = await repo.watchSessions().first;
    expect(opened, hasLength(1));
    expect(opened.single.id, id);
    expect(opened.single.startedAt.isAtSameMomentAs(start), isTrue);
    expect(opened.single.endedAt.isAtSameMomentAs(start), isTrue);

    final end = DateTime(2024, 6, 15, 12, 20);
    await repo.markOpenUntil(id, end);
    final updated = await repo.watchSessions().first;
    expect(updated.single.endedAt.isAtSameMomentAs(end), isTrue);
    expect(updated.single.duration, const Duration(minutes: 20));
  });
}
