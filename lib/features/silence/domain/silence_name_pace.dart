/// How long each petition name stays on screen, and how long it fades.
abstract final class SilenceNamePace {
  static const int stepSeconds = 5;
  static const int minSeconds = 5;
  static const int maxSeconds = 30;
  static const int defaultSeconds = 15;

  static int normalize(int seconds) {
    final clamped = seconds.clamp(minSeconds, maxSeconds);
    final steps = ((clamped - minSeconds) / stepSeconds).round();
    return minSeconds + steps * stepSeconds;
  }

  static int decrease(int seconds) =>
      normalize(normalize(seconds) - stepSeconds);

  static int increase(int seconds) =>
      normalize(normalize(seconds) + stepSeconds);

  static bool canDecrease(int seconds) => normalize(seconds) > minSeconds;

  static bool canIncrease(int seconds) => normalize(seconds) < maxSeconds;

  static Duration slotFor(int seconds) =>
      Duration(seconds: normalize(seconds));

  /// Fade in/out length scales with the slot; clamped for calm motion.
  static Duration fadeFor(int seconds) {
    final ms = (normalize(seconds) * 1000 ~/ 8).clamp(400, 2000);
    return Duration(milliseconds: ms);
  }
}
