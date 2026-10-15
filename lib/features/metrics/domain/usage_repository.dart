import 'journal_metrics.dart';

/// Local store of foreground sessions. No network.
abstract class UsageRepository {
  Future<int> beginSession(DateTime at);
  Future<void> markOpenUntil(int id, DateTime at);
  Stream<List<AppSession>> watchSessions();
}
