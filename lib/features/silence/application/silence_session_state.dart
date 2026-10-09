enum SilencePhase { setup, running }

class SilenceSessionState {
  const SilenceSessionState({
    this.phase = SilencePhase.setup,
    this.durationMinutes = 15,
    this.remaining = Duration.zero,
    this.names = const [],
    this.currentName,
  });

  final SilencePhase phase;
  final int durationMinutes;
  final Duration remaining;
  final List<String> names;
  final String? currentName;

  bool get isRunning => phase == SilencePhase.running;

  SilenceSessionState copyWith({
    SilencePhase? phase,
    int? durationMinutes,
    Duration? remaining,
    List<String>? names,
    String? currentName,
    bool clearCurrentName = false,
  }) {
    return SilenceSessionState(
      phase: phase ?? this.phase,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      remaining: remaining ?? this.remaining,
      names: names ?? this.names,
      currentName: clearCurrentName
          ? null
          : (currentName ?? this.currentName),
    );
  }
}
