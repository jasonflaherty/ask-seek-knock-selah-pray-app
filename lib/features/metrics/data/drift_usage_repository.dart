import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/journal_metrics.dart';
import '../domain/usage_repository.dart';

class DriftUsageRepository implements UsageRepository {
  DriftUsageRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> beginSession(DateTime at) {
    return _db
        .into(_db.appSessions)
        .insert(AppSessionsCompanion.insert(startedAt: at, endedAt: at));
  }

  @override
  Future<void> markOpenUntil(int id, DateTime at) {
    return (_db.update(_db.appSessions)..where((t) => t.id.equals(id))).write(
      AppSessionsCompanion(endedAt: Value(at)),
    );
  }

  @override
  Stream<List<AppSession>> watchSessions() {
    final query = _db.select(_db.appSessions)
      ..orderBy([(t) => OrderingTerm(expression: t.startedAt)]);
    return query.watch().map((rows) => [for (final row in rows) _map(row)]);
  }

  AppSession _map(AppSessionRow row) {
    return AppSession(
      id: row.id,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
    );
  }
}
