import '../../../core/utils/clock.dart';
import '../../prayers/domain/prayer_event.dart';
import '../../prayers/domain/prayer_repository.dart';

/// Thin wrapper over [PrayerRepository.logEvent] with viewed debouncing.
class EventLogger {
  EventLogger(this._repo, this._clock);

  final PrayerRepository _repo;
  final Clock _clock;

  final Map<int, DateTime> _lastViewedAt = {};
  final Map<int, DateTime> _visibleSince = {};
  final Set<int> _loggedThisAppearance = {};

  static const viewedDebounce = Duration(minutes: 10);
  static const viewedVisibleFor = Duration(seconds: 2);

  Future<void> prayed(int prayerId) =>
      _repo.logEvent(prayerId, PrayerEventType.prayed);

  Future<void> edited(int prayerId) =>
      _repo.logEvent(prayerId, PrayerEventType.edited);

  Future<void> answered(int prayerId) =>
      _repo.logEvent(prayerId, PrayerEventType.answered);

  Future<void> unanswered(int prayerId) =>
      _repo.logEvent(prayerId, PrayerEventType.unanswered);

  /// Call when visibility fraction changes for a prayer card.
  Future<void> onVisibilityChanged(int prayerId, double visibleFraction) async {
    final now = _clock.now();
    if (visibleFraction >= 0.6) {
      _visibleSince.putIfAbsent(prayerId, () => now);
      if (_loggedThisAppearance.contains(prayerId)) return;
      final since = _visibleSince[prayerId]!;
      if (now.difference(since) >= viewedVisibleFor) {
        final logged = await _maybeLogViewed(prayerId, now);
        if (logged) _loggedThisAppearance.add(prayerId);
      }
    } else {
      _visibleSince.remove(prayerId);
      _loggedThisAppearance.remove(prayerId);
    }
  }

  Future<bool> _maybeLogViewed(int prayerId, DateTime now) async {
    final last = _lastViewedAt[prayerId];
    if (last != null && now.difference(last) < viewedDebounce) {
      return false;
    }
    _lastViewedAt[prayerId] = now;
    await _repo.logEvent(prayerId, PrayerEventType.viewed);
    return true;
  }
}
