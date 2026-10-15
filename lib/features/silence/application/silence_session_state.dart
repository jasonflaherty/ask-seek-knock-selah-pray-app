import '../domain/silence_name_pace.dart';

enum SilencePhase { setup, running }

class SilenceSessionState {
  const SilenceSessionState({
    this.phase = SilencePhase.setup,
    this.durationMinutes = 15,
    this.paceSeconds = SilenceNamePace.defaultSeconds,
    this.remaining = Duration.zero,
    this.names = const [],
    this.currentName,
  });

  final SilencePhase phase;
  final int durationMinutes;
  final int paceSeconds;
  final Duration remaining;
  final List<String> names;
  final String? currentName;

  bool get isRunning => phase == SilencePhase.running;

  Duration get nameSlot => SilenceNamePace.slotFor(paceSeconds);

  Duration get nameFade => SilenceNamePace.fadeFor(paceSeconds);

  SilenceSessionState copyWith({
    SilencePhase? phase,
    int? durationMinutes,
    int? paceSeconds,
    Duration? remaining,
    List<String>? names,
    String? currentName,
    bool clearCurrentName = false,
  }) {
    return SilenceSessionState(
      phase: phase ?? this.phase,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      paceSeconds: paceSeconds ?? this.paceSeconds,
      remaining: remaining ?? this.remaining,
      names: names ?? this.names,
      currentName: clearCurrentName
          ? null
          : (currentName ?? this.currentName),
    );
  }
}
