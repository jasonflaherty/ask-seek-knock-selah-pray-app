/// Allowed prayer-timer lengths in whole minutes.
abstract final class SilenceDuration {
  static const int stepMinutes = 5;
  static const int minMinutes = 5;
  static const int maxMinutes = 60;
  static const int defaultMinutes = 15;

  /// Clamps [minutes] into [minMinutes]–[maxMinutes] and snaps to a 5-minute step.
  static int normalize(int minutes) {
    final clamped = minutes.clamp(minMinutes, maxMinutes);
    final steps = ((clamped - minMinutes) / stepMinutes).round();
    return minMinutes + steps * stepMinutes;
  }

  static int decrease(int minutes) =>
      normalize(normalize(minutes) - stepMinutes);

  static int increase(int minutes) =>
      normalize(normalize(minutes) + stepMinutes);

  static bool canDecrease(int minutes) => normalize(minutes) > minMinutes;

  static bool canIncrease(int minutes) => normalize(minutes) < maxMinutes;
}
