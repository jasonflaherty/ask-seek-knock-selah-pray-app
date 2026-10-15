import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../silence/data/wakelock_silence_wake_lock.dart';
import '../../silence/domain/silence_wake_lock.dart';
import '../domain/read_pray_phase.dart';

final readPrayWakeLockProvider = Provider<SilenceWakeLock>((ref) {
  return WakelockSilenceWakeLock();
});

final readPraySessionProvider =
    StateNotifierProvider<ReadPraySessionNotifier, ReadPraySessionState>((ref) {
  return ReadPraySessionNotifier(ref.watch(readPrayWakeLockProvider));
});

class ReadPraySessionState {
  const ReadPraySessionState({
    this.phase = ReadPrayPhase.setup,
    this.remainingSeconds = ReadPrayDuration.secondsEach,
    this.running = false,
  });

  final ReadPrayPhase phase;
  final int remainingSeconds;
  final bool running;

  ReadPraySessionState copyWith({
    ReadPrayPhase? phase,
    int? remainingSeconds,
    bool? running,
  }) {
    return ReadPraySessionState(
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      running: running ?? this.running,
    );
  }
}

class ReadPraySessionNotifier extends StateNotifier<ReadPraySessionState> {
  ReadPraySessionNotifier(this._wakeLock) : super(const ReadPraySessionState());

  final SilenceWakeLock _wakeLock;
  Timer? _tick;

  void startReading() {
    _tick?.cancel();
    state = const ReadPraySessionState(
      phase: ReadPrayPhase.read,
      remainingSeconds: ReadPrayDuration.secondsEach,
      running: true,
    );
    _wakeLock.enable();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void pause() {
    _tick?.cancel();
    _tick = null;
    state = state.copyWith(running: false);
    _wakeLock.disable();
  }

  void resume() {
    if (state.phase != ReadPrayPhase.read &&
        state.phase != ReadPrayPhase.pray) {
      return;
    }
    if (state.running) return;
    state = state.copyWith(running: true);
    _wakeLock.enable();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void skipToPray() {
    _beginPray();
  }

  void stop() {
    _tick?.cancel();
    _tick = null;
    _wakeLock.disable();
    state = const ReadPraySessionState();
  }

  void _onTick() {
    if (!state.running) return;
    if (state.remainingSeconds <= 1) {
      if (state.phase == ReadPrayPhase.read) {
        _beginPray();
      } else {
        _tick?.cancel();
        _tick = null;
        _wakeLock.disable();
        state = const ReadPraySessionState(
          phase: ReadPrayPhase.done,
          remainingSeconds: 0,
          running: false,
        );
      }
      return;
    }
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
  }

  void _beginPray() {
    _tick?.cancel();
    state = const ReadPraySessionState(
      phase: ReadPrayPhase.pray,
      remainingSeconds: ReadPrayDuration.secondsEach,
      running: true,
    );
    _wakeLock.enable();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _wakeLock.disable();
    super.dispose();
  }
}
