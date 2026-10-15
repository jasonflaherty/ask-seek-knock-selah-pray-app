import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/metrics/domain/journal_metrics.dart';
import 'package:selah/features/prayers/domain/prayer.dart';

Prayer _prayer({
  required int id,
  required DateTime createdAt,
  bool answered = false,
  DateTime? answeredAt,
  List<String> tags = const [],
}) {
  return Prayer(
    id: id,
    name: 'Petition $id',
    request: 'Request',
    isAnswered: answered,
    answeredAt: answeredAt,
    createdAt: createdAt,
    updatedAt: answeredAt ?? createdAt,
    tags: tags,
  );
}

void main() {
  test('weekly counts keep unanswered petitions active', () {
    final now = DateTime(2024, 6, 15, 12);
    final weeks = prayerStatusByWeek([
      _prayer(id: 1, createdAt: DateTime(2024, 6, 1, 9)),
      _prayer(
        id: 2,
        createdAt: DateTime(2024, 6, 11, 9),
        answered: true,
        answeredAt: DateTime(2024, 6, 14, 9),
      ),
    ], now: now);

    expect(weeks, hasLength(8));
    expect(weeks.first.weekStart, DateTime(2024, 4, 22));
    expect(weeks.first.active, 0);
    expect(weeks.first.answered, 0);

    final may27 = weeks.singleWhere(
      (week) => week.weekStart == DateTime(2024, 5, 27),
    );
    expect(may27.active, 1);
    expect(may27.answered, 0);

    final june3 = weeks.singleWhere(
      (week) => week.weekStart == DateTime(2024, 6, 3),
    );
    expect(june3.active, 1);
    expect(june3.answered, 0);

    expect(weeks.last.weekStart, DateTime(2024, 6, 10));
    expect(weeks.last.active, 1);
    expect(weeks.last.answered, 1);
  });

  test('tag totals count each tag once per petition', () {
    final totals = tagTotals([
      _prayer(
        id: 1,
        createdAt: DateTime(2024, 6, 1),
        tags: [' family ', 'family', ''],
      ),
      _prayer(id: 2, createdAt: DateTime(2024, 6, 2), tags: ['work', 'family']),
      _prayer(id: 3, createdAt: DateTime(2024, 6, 3), tags: ['alpha']),
      _prayer(id: 4, createdAt: DateTime(2024, 6, 4), tags: ['zeta']),
    ]);

    expect(totals.map((tag) => tag.name), ['family', 'alpha', 'work', 'zeta']);
    expect(totals.map((tag) => tag.count), [2, 1, 1, 1]);
  });

  test('open time splits across midnight and skips days outside the range', () {
    final days = usageByDay(
      [
        AppSession(
          id: 1,
          startedAt: DateTime(2024, 6, 14, 23),
          endedAt: DateTime(2024, 6, 15, 1, 30),
        ),
        AppSession(
          id: 2,
          startedAt: DateTime(2024, 6, 1, 8),
          endedAt: DateTime(2024, 6, 1, 9),
        ),
        AppSession(
          id: 3,
          startedAt: DateTime(2024, 6, 15, 8),
          endedAt: DateTime(2024, 6, 15, 8),
        ),
      ],
      now: DateTime(2024, 6, 15, 12),
      days: 14,
    );

    expect(days, hasLength(14));
    expect(days.first.day, DateTime(2024, 6, 2));
    expect(days.first.open, Duration.zero);
    expect(
      days.singleWhere((day) => day.day == DateTime(2024, 6, 14)).open,
      const Duration(hours: 1),
    );
    expect(days.last.open, const Duration(hours: 1, minutes: 30));
  });

  test('formatOpenDuration rounds down to minutes', () {
    expect(formatOpenDuration(Duration.zero), '0m');
    expect(formatOpenDuration(const Duration(seconds: 45)), '<1m');
    expect(formatOpenDuration(const Duration(minutes: 30)), '30m');
    expect(formatOpenDuration(const Duration(minutes: 60)), '1h');
    expect(formatOpenDuration(const Duration(minutes: 90)), '1h 30m');
  });
}
