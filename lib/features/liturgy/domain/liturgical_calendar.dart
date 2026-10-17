/// Western liturgical day resolution for 1662 collect selection.
///
/// Pure Dart. Date collects beat Morning/Evening office collects.
class LiturgicalCalendar {
  const LiturgicalCalendar();

  static const morningCutoffHour = 17;

  /// Gregorian Western Easter Sunday for [year].
  DateTime easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// First Sunday of Advent: Sunday on or after 27 November
  /// (nearest Sunday to 30 November; falls 27 Nov–3 Dec).
  DateTime adventSunday(int year) {
    final nov27 = DateTime(year, 11, 27);
    return _addDays(nov27, (DateTime.sunday - nov27.weekday) % 7);
  }

  DateTime _firstSundayAfter(DateTime date) {
    var d = _addDays(date, 1);
    while (d.weekday != DateTime.sunday) {
      d = _addDays(d, 1);
    }
    return d;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Calendar-day arithmetic that ignores DST hour shifts.
  DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// Calendar key for the liturgical day of [date], or null if none.
  ///
  /// Exact feasts win over Sundays. Weekdays without a proper return the
  /// preceding Sunday's key (collect of the day).
  String? dayKey(DateTime date) {
    final day = _dateOnly(date);
    final feast = _exactFeastKey(day);
    if (feast != null) return feast;

    if (day.weekday == DateTime.sunday) {
      return _sundayKey(day);
    }

    final sunday = _addDays(day, -(day.weekday % 7));
    return _sundayKey(sunday);
  }

  /// Next local instant when [todayAt] should be read again.
  ///
  /// Morning office becomes Evening at [morningCutoffHour]. Any selection
  /// can change at the next local midnight.
  DateTime nextRefresh(DateTime now) {
    final cutoff = DateTime(now.year, now.month, now.day, morningCutoffHour);
    if (now.isBefore(cutoff)) return cutoff;
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Prayer ids for the Today banner at [now].
  ///
  /// Date/Sunday collects replace office collects. Ordinary days without a
  /// day key fall back to Morning or Evening (cutover 17:00 local).
  TodaySelection todayAt(DateTime now) {
    final key = dayKey(now);
    if (key != null) {
      final ids = prayerIdsForKey(key);
      if (ids.isNotEmpty) {
        return TodaySelection(
          label: _labelForKey(key),
          calendarKey: key,
          prayerIds: ids,
          isOffice: false,
        );
      }
    }

    final isMorning = now.hour < morningCutoffHour;
    return TodaySelection(
      label: isMorning ? 'Morning' : 'Evening',
      calendarKey: isMorning ? 'morning' : 'evening',
      prayerIds: isMorning
          ? const ['morning-peace', 'morning-grace']
          : const ['evening-peace', 'evening-perils'],
      isOffice: true,
    );
  }

  List<String> prayerIdsForKey(String key) {
    if (key == 'good-friday') {
      return const [
        'good-friday-for-the-church',
        'good-friday-for-all-estates-of-men',
        'good-friday-for-those-who-know-not-christ',
      ];
    }
    final id = _keyToPrayerId[key];
    return id == null ? const [] : [id];
  }

  String? _exactFeastKey(DateTime day) {
    final y = day.year;
    final easter = easterSunday(y);
    final map = <DateTime, String>{
      DateTime(y, 12, 25): 'christmas',
      DateTime(y, 1, 1): 'circumcision',
      DateTime(y, 1, 6): 'epiphany',
      _addDays(easter, -46): 'ash-wednesday',
      _addDays(easter, -2): 'good-friday',
      _addDays(easter, -1): 'easter-even',
      easter: 'easter-day',
      _addDays(easter, 1): 'easter-monday',
      _addDays(easter, 2): 'easter-tuesday',
      _addDays(easter, 39): 'ascension',
      _addDays(easter, 49): 'whitsunday',
      _addDays(easter, 50): 'whit-monday',
      _addDays(easter, 51): 'whit-tuesday',
    };
    return map[day];
  }

  String? _sundayKey(DateTime sunday) {
    final y = sunday.year;
    final easter = easterSunday(y);
    final advent1 = adventSunday(y);

    if (sunday.month == 12 && sunday.day >= 26) {
      return 'christmas-sunday';
    }

    for (var i = 0; i < 4; i++) {
      if (sunday == _addDays(advent1, 7 * i)) {
        return 'advent-${i + 1}';
      }
    }

    final septuagesima = _addDays(easter, -63);
    final sexagesima = _addDays(easter, -56);
    final quinquagesima = _addDays(easter, -49);
    final lent1 = _addDays(easter, -42);
    final lent2 = _addDays(easter, -35);
    final lent3 = _addDays(easter, -28);
    final lent4 = _addDays(easter, -21);
    final lent5 = _addDays(easter, -14);
    final palm = _addDays(easter, -7);
    final easter1 = _addDays(easter, 7);
    final easter2 = _addDays(easter, 14);
    final easter3 = _addDays(easter, 21);
    final easter4 = _addDays(easter, 28);
    final easter5 = _addDays(easter, 35);
    final ascensionSunday = _addDays(easter, 42);
    final whitsunday = _addDays(easter, 49);
    final trinity = _addDays(easter, 56);

    final fixedSundays = <DateTime, String>{
      septuagesima: 'septuagesima',
      sexagesima: 'sexagesima',
      quinquagesima: 'quinquagesima',
      lent1: 'lent-1',
      lent2: 'lent-2',
      lent3: 'lent-3',
      lent4: 'lent-4',
      lent5: 'lent-5',
      palm: 'palm-sunday',
      easter: 'easter-day',
      easter1: 'easter-1',
      easter2: 'easter-2',
      easter3: 'easter-3',
      easter4: 'easter-4',
      easter5: 'easter-5',
      ascensionSunday: 'ascension-sunday',
      whitsunday: 'whitsunday',
      trinity: 'trinity',
    };
    final hit = fixedSundays[sunday];
    if (hit != null) return hit;

    final epiphany1 = _firstSundayAfter(DateTime(y, 1, 6));
    if (!sunday.isBefore(epiphany1) && sunday.isBefore(septuagesima)) {
      final weeks = _dateOnly(sunday).difference(epiphany1).inDays ~/ 7;
      if (weeks >= 0 && weeks <= 5) {
        return 'epiphany-${weeks + 1}';
      }
    }

    if (sunday.isAfter(trinity) && sunday.isBefore(advent1)) {
      final weeks = _dateOnly(sunday).difference(trinity).inDays ~/ 7;
      if (weeks >= 1 && weeks <= 25) return 'trinity-$weeks';
      if (weeks > 25) return 'trinity-25';
    }

    return null;
  }

  String _labelForKey(String key) {
    return switch (key) {
      'ash-wednesday' => 'Ash Wednesday',
      'christmas' => 'Christmas Day',
      'circumcision' => 'The Circumcision of Christ',
      'epiphany' => 'The Epiphany',
      'good-friday' => 'Good Friday',
      'easter-even' => 'Easter Even',
      'easter-day' => 'Easter Day',
      'easter-monday' => 'Monday in Easter Week',
      'easter-tuesday' => 'Tuesday in Easter Week',
      'ascension' => 'The Ascension Day',
      'whitsunday' => 'Whitsunday',
      'whit-monday' => 'Monday in Whitsun Week',
      'whit-tuesday' => 'Tuesday in Whitsun Week',
      'trinity' => 'Trinity Sunday',
      'palm-sunday' => 'The Sunday Next before Easter',
      'christmas-sunday' => 'The Sunday after Christmas Day',
      'septuagesima' => 'Septuagesima Sunday',
      'sexagesima' => 'Sexagesima Sunday',
      'quinquagesima' => 'Quinquagesima Sunday',
      'ascension-sunday' => 'Sunday after Ascension Day',
      _ => _titleCaseKey(key),
    };
  }

  String _titleCaseKey(String key) {
    if (key.startsWith('advent-')) {
      return 'The ${_ordinal(int.parse(key.split('-').last))} Sunday in Advent';
    }
    if (key.startsWith('epiphany-')) {
      return 'The ${_ordinal(int.parse(key.split('-').last))} Sunday after the Epiphany';
    }
    if (key.startsWith('lent-')) {
      return 'The ${_ordinal(int.parse(key.split('-').last))} Sunday in Lent';
    }
    if (RegExp(r'^easter-[1-5]$').hasMatch(key)) {
      return 'The ${_ordinal(int.parse(key.split('-').last))} Sunday after Easter';
    }
    if (key.startsWith('trinity-')) {
      return 'The ${_ordinal(int.parse(key.split('-').last))} Sunday after Trinity';
    }
    return key;
  }

  String _ordinal(int n) {
    const names = {
      1: 'First',
      2: 'Second',
      3: 'Third',
      4: 'Fourth',
      5: 'Fifth',
      6: 'Sixth',
      7: 'Seventh',
      8: 'Eighth',
      9: 'Ninth',
      10: 'Tenth',
      11: 'Eleventh',
      12: 'Twelfth',
      13: 'Thirteenth',
      14: 'Fourteenth',
      15: 'Fifteenth',
      16: 'Sixteenth',
      17: 'Seventeenth',
      18: 'Eighteenth',
      19: 'Nineteenth',
      20: 'Twentieth',
      21: 'Twenty-First',
      22: 'Twenty-Second',
      23: 'Twenty-Third',
      24: 'Twenty-Fourth',
      25: 'Twenty-Fifth',
    };
    return names[n] ?? '$n';
  }

  static const _keyToPrayerId = {
    'advent-1': 'the-first-sunday-in-advent',
    'advent-2': 'the-second-sunday-in-advent',
    'advent-3': 'the-third-sunday-in-advent',
    'advent-4': 'the-fourth-sunday-in-advent',
    'christmas': 'christmas-day',
    'christmas-sunday': 'the-sunday-after-christmas-day',
    'circumcision': 'the-circumcision-of-christ',
    'epiphany': 'the-epiphany',
    'epiphany-1': 'the-first-sunday-after-the-epiphany',
    'epiphany-2': 'the-second-sunday-after-the-epiphany',
    'epiphany-3': 'the-third-sunday-after-the-epiphany',
    'epiphany-4': 'the-fourth-sunday-after-the-epiphany',
    'epiphany-5': 'the-fifth-sunday-after-the-epiphany',
    'epiphany-6': 'the-sixth-sunday-after-the-epiphany',
    'septuagesima': 'septuagesima-sunday',
    'sexagesima': 'sexagesima-sunday',
    'quinquagesima': 'quinquagesima-sunday',
    'ash-wednesday': 'ash-wednesday',
    'lent-1': 'the-first-sunday-in-lent',
    'lent-2': 'the-second-sunday-in-lent',
    'lent-3': 'the-third-sunday-in-lent',
    'lent-4': 'the-fourth-sunday-in-lent',
    'lent-5': 'the-fifth-sunday-in-lent',
    'palm-sunday': 'the-sunday-next-before-easter',
    'easter-even': 'easter-even',
    'easter-day': 'easter-day',
    'easter-monday': 'monday-in-easter-week',
    'easter-tuesday': 'tuesday-in-easter-week',
    'easter-1': 'the-first-sunday-after-easter',
    'easter-2': 'the-second-sunday-after-easter',
    'easter-3': 'the-third-sunday-after-easter',
    'easter-4': 'the-fourth-sunday-after-easter',
    'easter-5': 'the-fifth-sunday-after-easter',
    'ascension': 'the-ascension-day',
    'ascension-sunday': 'sunday-after-ascension-day',
    'whitsunday': 'whitsunday',
    'whit-monday': 'monday-in-whitsun-week',
    'whit-tuesday': 'tuesday-in-whitsun-week',
    'trinity': 'trinity-sunday',
    'trinity-1': 'the-first-sunday-after-trinity',
    'trinity-2': 'the-second-sunday-after-trinity',
    'trinity-3': 'the-third-sunday-after-trinity',
    'trinity-4': 'the-fourth-sunday-after-trinity',
    'trinity-5': 'the-fifth-sunday-after-trinity',
    'trinity-6': 'the-sixth-sunday-after-trinity',
    'trinity-7': 'the-seventh-sunday-after-trinity',
    'trinity-8': 'the-eighth-sunday-after-trinity',
    'trinity-9': 'the-ninth-sunday-after-trinity',
    'trinity-10': 'the-tenth-sunday-after-trinity',
    'trinity-11': 'the-eleventh-sunday-after-trinity',
    'trinity-12': 'the-twelfth-sunday-after-trinity',
    'trinity-13': 'the-thirteenth-sunday-after-trinity',
    'trinity-14': 'the-fourteenth-sunday-after-trinity',
    'trinity-15': 'the-fifteenth-sunday-after-trinity',
    'trinity-16': 'the-sixteenth-sunday-after-trinity',
    'trinity-17': 'the-seventeenth-sunday-after-trinity',
    'trinity-18': 'the-eighteenth-sunday-after-trinity',
    'trinity-19': 'the-nineteenth-sunday-after-trinity',
    'trinity-20': 'the-twentieth-sunday-after-trinity',
    'trinity-21': 'the-twenty-first-sunday-after-trinity',
    'trinity-22': 'the-twenty-second-sunday-after-trinity',
    'trinity-23': 'the-twenty-third-sunday-after-trinity',
    'trinity-24': 'the-twenty-fourth-sunday-after-trinity',
    'trinity-25': 'the-twenty-fifth-sunday-after-trinity',
  };
}

class TodaySelection {
  const TodaySelection({
    required this.label,
    required this.calendarKey,
    required this.prayerIds,
    required this.isOffice,
  });

  final String label;
  final String calendarKey;
  final List<String> prayerIds;
  final bool isOffice;
}
