import 'dart:async';

import 'package:selah/features/metrics/domain/journal_metrics.dart';
import 'package:selah/features/metrics/domain/usage_repository.dart';

class FakeUsageRepository implements UsageRepository {
  final List<AppSession> sessions = [];
  final _updates = StreamController<List<AppSession>>.broadcast();
  int _nextId = 1;
  bool _closed = false;

  void dispose() {
    _closed = true;
    _updates.close();
  }

  void _emit() {
    if (_closed || _updates.isClosed) return;
    _updates.add(List<AppSession>.unmodifiable(sessions));
  }

  @override
  Future<int> beginSession(DateTime at) async {
    final id = _nextId++;
    sessions.add(AppSession(id: id, startedAt: at, endedAt: at));
    _emit();
    return id;
  }

  @override
  Future<void> markOpenUntil(int id, DateTime at) async {
    final index = sessions.indexWhere((session) => session.id == id);
    if (index < 0) return;
    sessions[index] = sessions[index].copyWith(endedAt: at);
    _emit();
  }

  @override
  Stream<List<AppSession>> watchSessions() async* {
    yield List<AppSession>.unmodifiable(sessions);
    yield* _updates.stream;
  }
}
