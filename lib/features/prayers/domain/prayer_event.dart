enum PrayerEventType {
  viewed,
  prayed,
  answered,
  unanswered,
  edited,
}

extension PrayerEventTypeX on PrayerEventType {
  String get storageValue => name;

  static PrayerEventType fromStorage(String value) {
    return PrayerEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrayerEventType.viewed,
    );
  }
}
