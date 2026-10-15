import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../../core/utils/seeded_shuffle.dart';
import '../../prayers/domain/prayer.dart';
import '../../prayers/domain/prayer_repository.dart';
import '../data/audio_silence_bell.dart';
import '../data/wakelock_silence_wake_lock.dart';
import '../domain/silence_bell.dart';
import '../domain/silence_duration.dart';
import '../domain/silence_focus.dart';
import '../domain/silence_name_cycle.dart';
import '../domain/silence_name_pace.dart';
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

/// Seed used to shuffle petition names for a silence session.
final silenceShuffleSeedProvider = Provider<int Function()>((ref) {
  return () => DateTime.now().microsecondsSinceEpoch;
});

final silenceSessionProvider =
    StateNotifierProvider<SilenceSessionNotifier, SilenceSessionState>((ref) {
  return SilenceSessionNotifier(
    repo: ref.watch(prayerRepositoryProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    bell: ref.watch(silenceBellProvider),
    wakeLock: ref.watch(silenceWakeLockProvider),
    shuffleSeed: ref.watch(silenceShuffleSeedProvider),
  );
});

class SilenceSessionNotifier extends StateNotifier<SilenceSessionState> {
  SilenceSessionNotifier({
    required this._repo,
    required SharedPreferences prefs,
    required this._bell,
    required this._wakeLock,
    required int Function() shuffleSeed,
  })  : _prefs = prefs,
        _shuffleSeed = shuffleSeed,
        super(
          SilenceSessionState(
            durationMinutes: SilenceDuration.normalize(
              prefs.getInt(_durationKey) ?? SilenceDuration.defaultMinutes,
            ),
            paceSeconds: SilenceNamePace.normalize(
              prefs.getInt(_paceKey) ?? SilenceNamePace.defaultSeconds,
            ),
          ),
        ) {
    _namesSub = _repo
        .watchPrayers(filter: AnswerFilter.active)
        .listen(_onPrayers);
  }

  static const _durationKey = 'silence_duration_minutes';
  static const _paceKey = 'silence_name_pace_seconds';

  final PrayerRepository _repo;
  final SharedPreferences _prefs;
  final SilenceBell _bell;
  final SilenceWakeLock _wakeLock;
  final int Function() _shuffleSeed;

  StreamSubscription<List<Prayer>>? _namesSub;
  Timer? _tick;
  List<String> _sourceNames = const [];
  List<String> _names = const [];
  Duration _elapsed = Duration.zero;
  int? _sessionSeed;

  Duration get _slot => SilenceNamePace.slotFor(state.paceSeconds);

  String? _nameAt(Duration elapsed) => SilenceNameCycle.nameAt(
        names: _names,
        elapsed: elapsed,
        slot: _slot,
      );

  void _onPrayers(List<Prayer> prayers) {
    _sourceNames = silenceFocusNames(prayers);
    _names = _orderedNames(_sourceNames);
    if (!mounted) return;
    if (state.isRunning) {
      state = state.copyWith(
        names: _names,
        currentName: _nameAt(_elapsed),
        clearCurrentName: _names.isEmpty,
      );
    } else {
      state = state.copyWith(names: _names);
    }
  }

  List<String> _orderedNames(List<String> source) {
    final seed = _sessionSeed;
    if (seed == null || source.length < 2) return source;
    return seededShuffle(source, seed);
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

  Future<void> setPaceSeconds(int seconds) async {
    final normalized = SilenceNamePace.normalize(seconds);
    if (normalized == state.paceSeconds) return;
    final oldSlot = _slot;
    final newSlot = SilenceNamePace.slotFor(normalized);
    if (state.isRunning) {
      _elapsed = SilenceNameCycle.remapElapsed(
        elapsed: _elapsed,
        oldSlot: oldSlot,
        newSlot: newSlot,
      );
    }
    state = state.copyWith(
      paceSeconds: normalized,
      currentName: state.isRunning ? _nameAt(_elapsed) : state.currentName,
      clearCurrentName: state.isRunning && _names.isEmpty,
    );
    await _prefs.setInt(_paceKey, normalized);
  }

  Future<void> decreasePace() =>
      setPaceSeconds(SilenceNamePace.decrease(state.paceSeconds));

  Future<void> increasePace() =>
      setPaceSeconds(SilenceNamePace.increase(state.paceSeconds));

  Future<void> start() async {
    if (state.isRunning) return;
    final total = Duration(minutes: state.durationMinutes);
    _elapsed = Duration.zero;
    _sessionSeed = _shuffleSeed();
    _names = _orderedNames(_sourceNames);
    state = state.copyWith(
      phase: SilencePhase.running,
      remaining: total,
      names: _names,
      currentName: _nameAt(Duration.zero),
      clearCurrentName: _names.isEmpty,
    );
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_onTick());
    });
    try {
      await _wakeLock.enable();
    } catch (_) {}
  }

  Future<void> stop({bool playBell = false}) async {
    if (!state.isRunning) return;
    _tick?.cancel();
    _tick = null;
    _elapsed = Duration.zero;
    _sessionSeed = null;
    _names = _sourceNames;
    final minutes = state.durationMinutes;
    final pace = state.paceSeconds;
    // Update UI before awaiting platform plugins (wake lock / audio).
    state = SilenceSessionState(
      durationMinutes: minutes,
      paceSeconds: pace,
      names: _names,
    );
    try {
      await _wakeLock.disable();
    } catch (_) {}
    if (playBell) {
      try {
        await _bell.chime();
      } catch (_) {}
    }
  }

  void skipName() {
    if (!state.isRunning || _names.isEmpty) return;
    _elapsed = SilenceNameCycle.skipToNextSlot(_elapsed, slot: _slot);
    state = state.copyWith(currentName: _nameAt(_elapsed));
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
      currentName: _nameAt(_elapsed),
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
