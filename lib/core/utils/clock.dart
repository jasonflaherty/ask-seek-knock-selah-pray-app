/// Injectable clock so tests can control "now".
abstract class Clock {
  DateTime now();

  /// True when [now] moves on its own. Fakes stay put until set.
  bool get followsWallClock;
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  bool get followsWallClock => true;
}

class FakeClock implements Clock {
  FakeClock([DateTime? initial, this.followsWallClock = false])
    : _now = initial ?? DateTime(2024, 6, 15, 12);

  @override
  final bool followsWallClock;

  DateTime _now;

  @override
  DateTime now() => _now;

  void set(DateTime value) => _now = value;

  void advance(Duration by) => _now = _now.add(by);
}
