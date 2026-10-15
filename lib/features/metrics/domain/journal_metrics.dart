import '../../prayers/domain/prayer.dart';

/// One local week of active and answered petition counts.
class PrayerWeekPoint {
  const PrayerWeekPoint({
    required this.weekStart,
    required this.active,
    required this.answered,
  });

  /// Monday of this week, at local midnight.
  final DateTime weekStart;
  final int active;
  final int answered;
}

/// How many petitions use one tag.
class TagTotal {
  const TagTotal({required this.name, required this.count});

  final String name;
  final int count;
}

/// Foreground time stored for one visit.
class AppSession {
  const AppSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
  });

  final int id;
  final DateTime startedAt;
  final DateTime endedAt;

  Duration get duration {
    final span = endedAt.difference(startedAt);
    return span.isNegative ? Duration.zero : span;
  }

  AppSession copyWith({DateTime? endedAt}) {
    return AppSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

/// Open time on one local calendar day.
class UsageDay {
  const UsageDay({required this.day, required this.open});

  final DateTime day;
  final Duration open;
}

/// Active and answered counts, plus tag totals, for the metrics screen.
class PrayerMetrics {
  const PrayerMetrics({
    required this.active,
    required this.answered,
    required this.weeks,
    required this.tags,
  });

  final int active;
  final int answered;
  final List<PrayerWeekPoint> weeks;
  final List<TagTotal> tags;
}

/// Monday of the local week that contains [instant].
DateTime startOfWeek(DateTime instant) {
  final day = DateTime(instant.year, instant.month, instant.day);
  return DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - DateTime.monday),
  );
}

DateTime addCalendarDays(DateTime day, int days) {
  return DateTime(day.year, day.month, day.day + days);
}

/// Snapshot of active and answered petitions at the end of each week.
///
/// The latest week is counted through [now]. Earlier weeks are counted
/// through the following Monday at midnight.
List<PrayerWeekPoint> prayerStatusByWeek(
  List<Prayer> prayers, {
  required DateTime now,
  int weeks = 8,
}) {
  if (weeks < 1) return const [];
  final currentWeek = startOfWeek(now);
  final points = <PrayerWeekPoint>[];
  for (var i = weeks - 1; i >= 0; i--) {
    final weekStart = addCalendarDays(currentWeek, -7 * i);
    final weekEnd = addCalendarDays(weekStart, 7);
    final isCurrent = weekEnd.isAfter(now);
    final counts = _countsAt(
      prayers,
      isCurrent ? now : weekEnd,
      inclusive: isCurrent,
    );
    points.add(
      PrayerWeekPoint(
        weekStart: weekStart,
        active: counts.active,
        answered: counts.answered,
      ),
    );
  }
  return points;
}

/// Petition counts per tag name, highest count first.
List<TagTotal> tagTotals(List<Prayer> prayers) {
  final counts = <String, int>{};
  for (final prayer in prayers) {
    final seen = <String>{};
    for (final raw in prayer.tags) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      if (!seen.add(name)) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  final totals = [
    for (final entry in counts.entries)
      TagTotal(name: entry.key, count: entry.value),
  ];
  totals.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;
    return a.name.compareTo(b.name);
  });
  return totals;
}

/// Open time per day for the [days] ending on [now], oldest first.
List<UsageDay> usageByDay(
  List<AppSession> sessions, {
  required DateTime now,
  required int days,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final start = addCalendarDays(today, -(days - 1));
  final totals = <DateTime, Duration>{
    for (var i = 0; i < days; i++) addCalendarDays(start, i): Duration.zero,
  };
  for (final session in sessions) {
    var cursor = session.startedAt;
    final end = session.endedAt.isBefore(cursor) ? cursor : session.endedAt;
    while (cursor.isBefore(end)) {
      final day = DateTime(cursor.year, cursor.month, cursor.day);
      final nextDay = addCalendarDays(day, 1);
      final sliceEnd = end.isBefore(nextDay) ? end : nextDay;
      if (!sliceEnd.isAfter(cursor)) break;
      final slice = sliceEnd.difference(cursor);
      final existing = totals[day];
      if (existing != null) {
        totals[day] = existing + slice;
      }
      cursor = sliceEnd;
    }
  }
  return [
    for (var i = 0; i < days; i++)
      UsageDay(
        day: addCalendarDays(start, i),
        open: totals[addCalendarDays(start, i)]!,
      ),
  ];
}

/// Short label for a duration, rounded down to minutes.
String formatOpenDuration(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds <= 0) return '0m';
  if (seconds < 60) return '<1m';
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (hours == 0) return '${minutes}m';
  if (remain == 0) return '${hours}h';
  return '${hours}h ${remain}m';
}

DateTime? _answeredAt(Prayer prayer) {
  if (!prayer.isAnswered) return null;
  return prayer.answeredAt ?? prayer.updatedAt;
}

({int active, int answered}) _countsAt(
  List<Prayer> prayers,
  DateTime instant, {
  required bool inclusive,
}) {
  var active = 0;
  var answered = 0;
  for (final prayer in prayers) {
    final created = prayer.createdAt;
    final exists = inclusive
        ? !created.isAfter(instant)
        : created.isBefore(instant);
    if (!exists) continue;
    final answeredAt = _answeredAt(prayer);
    final wasAnswered =
        answeredAt != null &&
        (inclusive
            ? !answeredAt.isAfter(instant)
            : answeredAt.isBefore(instant));
    if (wasAnswered) {
      answered++;
    } else {
      active++;
    }
  }
  return (active: active, answered: answered);
}
