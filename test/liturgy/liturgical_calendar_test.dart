import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/liturgy/domain/liturgical_calendar.dart';

void main() {
  const calendar = LiturgicalCalendar();

  test('western Easter dates', () {
    expect(calendar.easterSunday(2024), DateTime(2024, 3, 31));
    expect(calendar.easterSunday(2025), DateTime(2025, 4, 20));
    expect(calendar.easterSunday(2026), DateTime(2026, 4, 5));
  });

  test('Ash Wednesday is 46 days before Easter', () {
    expect(calendar.dayKey(DateTime(2024, 2, 14)), 'ash-wednesday');
    expect(calendar.dayKey(DateTime(2025, 3, 5)), 'ash-wednesday');
  });

  test('Advent 1 is the Sunday on or after 27 November', () {
    expect(calendar.adventSunday(2024), DateTime(2024, 12, 1));
    expect(calendar.adventSunday(2025), DateTime(2025, 11, 30));
    expect(calendar.dayKey(DateTime(2024, 12, 1)), 'advent-1');
    expect(calendar.dayKey(DateTime(2025, 11, 30)), 'advent-1');
  });

  test('Trinity Sunday is 56 days after Easter', () {
    expect(calendar.dayKey(DateTime(2024, 5, 26)), 'trinity');
    expect(calendar.dayKey(DateTime(2025, 6, 15)), 'trinity');
  });

  test('feast day beats morning and evening office', () {
    final morningAsh = calendar.todayAt(DateTime(2024, 2, 14, 9));
    expect(morningAsh.isOffice, isFalse);
    expect(morningAsh.prayerIds, ['ash-wednesday']);

    final eveningAsh = calendar.todayAt(DateTime(2024, 2, 14, 20));
    expect(eveningAsh.isOffice, isFalse);
    expect(eveningAsh.prayerIds, ['ash-wednesday']);
  });

  test('Good Friday returns all three collects', () {
    final today = calendar.todayAt(DateTime(2024, 3, 29, 12));
    expect(today.calendarKey, 'good-friday');
    expect(today.prayerIds, hasLength(3));
  });

  test('morning and evening cutover when no day collect', () {
    // 5 Jan 2025 is a Sunday between Circumcision and Epiphany with no proper.
    final morning = calendar.todayAt(DateTime(2025, 1, 5, 10));
    expect(morning.isOffice, isTrue);
    expect(morning.prayerIds, ['morning-peace', 'morning-grace']);

    final evening = calendar.todayAt(DateTime(2025, 1, 5, 17));
    expect(evening.isOffice, isTrue);
    expect(evening.prayerIds, ['evening-peace', 'evening-perils']);
  });

  test('weekday uses preceding Sunday collect', () {
    // Monday after Advent 1 2024 (1 Dec was Sunday).
    expect(calendar.dayKey(DateTime(2024, 12, 2)), 'advent-1');
  });
}
