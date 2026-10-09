import 'prayer.dart';
import 'prayer_event.dart';

abstract class PrayerRepository {
  Stream<List<Prayer>> watchPrayers({required AnswerFilter filter});
  Future<Prayer?> getPrayer(int id);
  Future<Prayer?> getPrayerBySyncId(String syncId);
  Future<int> createPrayer(NewPrayer input);
  Future<void> updatePrayer(int id, PrayerUpdate input);
  Future<void> deletePrayer(int id);

  /// Removes a prayer without writing a sync tombstone (remote-driven delete).
  Future<void> purgePrayer(int id);

  Future<void> setAnswered(int id, {required bool answered, String? note});
  Future<void> logEvent(int prayerId, PrayerEventType type);
  Future<List<String>> allTagLabels();

  /// Distinct person labels, sorted case-insensitively (excludes empty).
  Future<List<String>> allPersonNames();

  /// Church-shared prayers only (for spreadsheet sync).
  Future<List<Prayer>> churchPrayers();

  /// Assign a sync id and mark shared, or clear shared and write a tombstone.
  Future<void> setShared(
    int id, {
    required bool shared,
    String? authorEmail,
  });
}
