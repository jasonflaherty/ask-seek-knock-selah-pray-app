import 'prayer.dart';
import 'prayer_event.dart';
import 'share_scope.dart';

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

  /// Prayers with group or church scope (for sync).
  Future<List<Prayer>> sharedPrayers();

  /// Assign scope and sync id, or clear share and write a tombstone.
  Future<void> setShareScope(
    int id, {
    required ShareScope shareScope,
    String? authorEmail,
    String? authorDisplayName,
    String? groupId,
    String? churchId,
  });
}
