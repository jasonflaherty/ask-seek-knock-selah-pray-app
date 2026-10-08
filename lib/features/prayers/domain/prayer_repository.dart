import 'prayer.dart';
import 'prayer_event.dart';

abstract class PrayerRepository {
  Stream<List<Prayer>> watchPrayers({required AnswerFilter filter});
  Future<Prayer?> getPrayer(int id);
  Future<int> createPrayer(NewPrayer input);
  Future<void> updatePrayer(int id, PrayerUpdate input);
  Future<void> deletePrayer(int id);
  Future<void> setAnswered(int id, {required bool answered, String? note});
  Future<void> logEvent(int prayerId, PrayerEventType type);
  Future<List<String>> allTagLabels();
}
