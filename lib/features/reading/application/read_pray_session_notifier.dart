import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../silence/application/silence_session_notifier.dart';
import '../../silence/data/wakelock_silence_wake_lock.dart';
import '../../silence/domain/silence_bell.dart';
import '../../silence/domain/silence_wake_lock.dart';
import '../domain/read_pray_phase.dart';

final readPrayWakeLockProvider = Provider<SilenceWakeLock>((ref) {
  return WakelockSilenceWakeLock();
});

final readPraySessionProvider =
    StateNotifierProvider<ReadPraySessionNotifier, ReadPraySessionState>((ref) {
  return ReadPraySessionNotifier(
    wakeLock: ref.watch(readPrayWakeLockProvider),
    bell: ref.watch(silenceBellProvider),
  );
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
  ReadPraySessionNotifier({
    required SilenceWakeLock this._wakeLock,
    required SilenceBell this._bell,
  }) : super(const ReadPraySessionState());

  final SilenceWakeLock _wakeLock;
  final SilenceBell _bell;
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
    _beginPray(chime: false);
  }

  void stop() {
    _tick?.cancel();
    _tick = null;
    _wakeLock.disable();
    state = const ReadPraySessionState();
  }

  Future<void> _onTick() async {
    if (!state.running) return;
    if (state.remainingSeconds <= 1) {
      if (state.phase == ReadPrayPhase.read) {
        await _beginPray(chime: true);
      } else {
        _tick?.cancel();
        _tick = null;
        _wakeLock.disable();
        state = const ReadPraySessionState(
          phase: ReadPrayPhase.done,
          remainingSeconds: 0,
          running: false,
        );
        try {
          await _bell.chime();
        } catch (_) {}
      }
      return;
    }
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
  }

  @visibleForTesting
  Future<void> debugForceOneSecondLeftAndTick() async {
    state = state.copyWith(remainingSeconds: 1, running: true);
    await _onTick();
  }

  Future<void> _beginPray({required bool chime}) async {
    _tick?.cancel();
    state = const ReadPraySessionState(
      phase: ReadPrayPhase.pray,
      remainingSeconds: ReadPrayDuration.secondsEach,
      running: true,
    );
    _wakeLock.enable();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    if (chime) {
      try {
        await _bell.chime();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _wakeLock.disable();
    super.dispose();
  }
}
