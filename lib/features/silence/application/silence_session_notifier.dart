import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../prayers/domain/prayer.dart';
import '../../prayers/domain/prayer_repository.dart';
import '../data/audio_silence_bell.dart';
import '../data/wakelock_silence_wake_lock.dart';
import '../domain/silence_bell.dart';
import '../domain/silence_duration.dart';
import '../domain/silence_focus.dart';
import '../domain/silence_name_cycle.dart';
import '../domain/silence_wake_lock.dart';
import 'silence_session_state.dart';

final silenceBellProvider = Provider<SilenceBell>((ref) {
  final bell = AudioSilenceBell();
  ref.onDispose(bell.dispose);
  return bell;
});

final silenceWakeLockProvider = Provider<SilenceWakeLock>((ref) {
  return WakelockSilenceWakeLock();
});

final silenceSessionProvider =
    StateNotifierProvider<SilenceSessionNotifier, SilenceSessionState>((ref) {
  return SilenceSessionNotifier(
    repo: ref.watch(prayerRepositoryProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    bell: ref.watch(silenceBellProvider),
    wakeLock: ref.watch(silenceWakeLockProvider),
  );
});

class SilenceSessionNotifier extends StateNotifier<SilenceSessionState> {
  SilenceSessionNotifier({
    required this._repo,
    required SharedPreferences prefs,
    required this._bell,
    required this._wakeLock,
  })  : _prefs = prefs,
        super(
          SilenceSessionState(
            durationMinutes: SilenceDuration.normalize(
              prefs.getInt(_durationKey) ?? SilenceDuration.defaultMinutes,
            ),
          ),
        ) {
    _namesSub = _repo
        .watchPrayers(filter: AnswerFilter.active)
        .listen(_onPrayers);
  }

  static const _durationKey = 'silence_duration_minutes';

  final PrayerRepository _repo;
  final SharedPreferences _prefs;
  final SilenceBell _bell;
  final SilenceWakeLock _wakeLock;

  StreamSubscription<List<Prayer>>? _namesSub;
  Timer? _tick;
  List<String> _names = const [];
  Duration _elapsed = Duration.zero;

  void _onPrayers(List<Prayer> prayers) {
    _names = silenceFocusNames(prayers);
    if (!mounted) return;
    if (state.isRunning) {
      state = state.copyWith(
        names: _names,
        currentName: SilenceNameCycle.nameAt(
          names: _names,
          elapsed: _elapsed,
        ),
        clearCurrentName: _names.isEmpty,
      );
    } else {
      state = state.copyWith(names: _names);
    }
  }

  Future<void> setDurationMinutes(int minutes) async {
    if (state.isRunning) return;
    final normalized = SilenceDuration.normalize(minutes);
    state = state.copyWith(durationMinutes: normalized);
    await _prefs.setInt(_durationKey, normalized);
  }

  Future<void> decreaseDuration() =>
      setDurationMinutes(SilenceDuration.decrease(state.durationMinutes));

  Future<void> increaseDuration() =>
      setDurationMinutes(SilenceDuration.increase(state.durationMinutes));

  Future<void> start() async {
    if (state.isRunning) return;
    final total = Duration(minutes: state.durationMinutes);
    _elapsed = Duration.zero;
    state = state.copyWith(
      phase: SilencePhase.running,
      remaining: total,
      names: _names,
      currentName: SilenceNameCycle.nameAt(
        names: _names,
        elapsed: Duration.zero,
      ),
      clearCurrentName: _names.isEmpty,
    );
    await _wakeLock.enable();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_onTick());
    });
  }

  Future<void> stop({bool playBell = false}) async {
    _tick?.cancel();
    _tick = null;
    _elapsed = Duration.zero;
    await _wakeLock.disable();
    if (playBell) {
      await _bell.chime();
    }
    if (!mounted) return;
    state = SilenceSessionState(
      durationMinutes: state.durationMinutes,
      names: _names,
    );
  }

  Future<void> _onTick() async {
    if (!mounted || !state.isRunning) return;
    _elapsed += const Duration(seconds: 1);
    final next = state.remaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      await stop(playBell: true);
      return;
    }
    state = state.copyWith(
      remaining: next,
      currentName: SilenceNameCycle.nameAt(
        names: _names,
        elapsed: _elapsed,
      ),
      clearCurrentName: _names.isEmpty,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _namesSub?.cancel();
    unawaited(_wakeLock.disable());
    super.dispose();
  }
}
