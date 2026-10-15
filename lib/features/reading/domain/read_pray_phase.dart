enum ReadPrayPhase {
  setup,
  read,
  pray,
  done,
}

abstract final class ReadPrayDuration {
  static const int minutesEach = 10;
  static const int secondsEach = minutesEach * 60;
}
