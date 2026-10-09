/// How long each petition name stays on screen during a silence session.
///
/// Each name holds for [slot] (15 seconds). Long lists cycle from the start
/// until the timer ends rather than compressing below [minSlot].
abstract final class SilenceNameCycle {
  static const Duration slot = Duration(seconds: 15);
  static const Duration minSlot = Duration(seconds: 8);

  /// Index into [names] for [elapsed], or null when there are no names.
  static int? nameIndexAt({
    required List<String> names,
    required Duration elapsed,
    Duration slot = SilenceNameCycle.slot,
  }) {
    if (names.isEmpty) return null;
    if (elapsed.isNegative) return 0;
    final slotMs = slot.inMilliseconds.clamp(minSlot.inMilliseconds, 1 << 30);
    final index = elapsed.inMilliseconds ~/ slotMs;
    return index % names.length;
  }

  /// Name shown at [elapsed], or null when [names] is empty.
  static String? nameAt({
    required List<String> names,
    required Duration elapsed,
    Duration slot = SilenceNameCycle.slot,
  }) {
    final index = nameIndexAt(names: names, elapsed: elapsed, slot: slot);
    if (index == null) return null;
    return names[index];
  }

  /// Elapsed time at the start of the next name slot after [elapsed].
  static Duration skipToNextSlot(
    Duration elapsed, {
    Duration slot = SilenceNameCycle.slot,
  }) {
    final slotMs = slot.inMilliseconds.clamp(minSlot.inMilliseconds, 1 << 30);
    final current = elapsed.inMilliseconds < 0 ? 0 : elapsed.inMilliseconds;
    final nextSlot = (current ~/ slotMs) + 1;
    return Duration(milliseconds: nextSlot * slotMs);
  }
}
