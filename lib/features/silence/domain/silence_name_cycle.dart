/// How petition names advance during a silence session.
///
/// Each name holds for [slot]. Long lists cycle from the start until the
/// timer ends rather than compressing the slot.
abstract final class SilenceNameCycle {
  static const Duration defaultSlot = Duration(seconds: 15);

  /// Index into [names] for [elapsed], or null when there are no names.
  static int? nameIndexAt({
    required List<String> names,
    required Duration elapsed,
    Duration slot = defaultSlot,
  }) {
    if (names.isEmpty) return null;
    if (elapsed.isNegative) return 0;
    final slotMs = slot.inMilliseconds;
    if (slotMs <= 0) return 0;
    final index = elapsed.inMilliseconds ~/ slotMs;
    return index % names.length;
  }

  /// Name shown at [elapsed], or null when [names] is empty.
  static String? nameAt({
    required List<String> names,
    required Duration elapsed,
    Duration slot = defaultSlot,
  }) {
    final index = nameIndexAt(names: names, elapsed: elapsed, slot: slot);
    if (index == null) return null;
    return names[index];
  }

  /// Elapsed time at the start of the next name slot after [elapsed].
  static Duration skipToNextSlot(
    Duration elapsed, {
    Duration slot = defaultSlot,
  }) {
    final slotMs = slot.inMilliseconds;
    if (slotMs <= 0) return elapsed;
    final current = elapsed.inMilliseconds < 0 ? 0 : elapsed.inMilliseconds;
    final nextSlot = (current ~/ slotMs) + 1;
    return Duration(milliseconds: nextSlot * slotMs);
  }

  /// Remap [elapsed] so the current name index is preserved under [newSlot].
  static Duration remapElapsed({
    required Duration elapsed,
    required Duration oldSlot,
    required Duration newSlot,
  }) {
    final oldMs = oldSlot.inMilliseconds <= 0 ? 1 : oldSlot.inMilliseconds;
    final index = elapsed.inMilliseconds < 0
        ? 0
        : elapsed.inMilliseconds ~/ oldMs;
    final newMs = newSlot.inMilliseconds <= 0 ? 1 : newSlot.inMilliseconds;
    return Duration(milliseconds: index * newMs);
  }
}
