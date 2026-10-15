import 'dart:async';

import '../../../core/utils/clock.dart';
import '../domain/usage_repository.dart';

/// Records foreground time. A heartbeat keeps the open session if the app
/// is stopped without a pause event.
class UsageTracker {
  UsageTracker(
    this._repo,
    this._clock, {
    Duration heartbeat = const Duration(seconds: 15),
  }) : _heartbeatEvery = heartbeat;

  final UsageRepository _repo;
  final Clock _clock;
  final Duration _heartbeatEvery;

  Timer? _heartbeat;
  int? _sessionId;
  bool _foreground = false;

  int? get openSessionId => _sessionId;

  Future<void> onResumed() async {
    if (_foreground) return;
    _foreground = true;
    final int id;
    try {
      id = await _repo.beginSession(_clock.now());
    } catch (_) {
      _foreground = false;
      rethrow;
    }
    if (!_foreground) {
      await _repo.markOpenUntil(id, _clock.now());
      return;
    }
    _sessionId = id;
    _cancelHeartbeat();
    _heartbeat = Timer.periodic(_heartbeatEvery, (_) => _touch());
  }

  Future<void> onBackgrounded() {
    final id = _takeSession();
    if (id == null) return Future<void>.value();
    return _repo.markOpenUntil(id, _clock.now());
  }

  void dispose() {
    final id = _takeSession();
    if (id == null) return;
    _repo.markOpenUntil(id, _clock.now());
  }

  void _touch() {
    final id = _sessionId;
    if (id == null) return;
    _repo.markOpenUntil(id, _clock.now());
  }

  int? _takeSession() {
    if (!_foreground && _sessionId == null) return null;
    _foreground = false;
    _cancelHeartbeat();
    final id = _sessionId;
    _sessionId = null;
    return id;
  }

  void _cancelHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }
}
