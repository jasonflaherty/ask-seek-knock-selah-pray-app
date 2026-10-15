/// One Scripture shown on the journal home meditation banner.
class HomeMeditationVerse {
  const HomeMeditationVerse({
    required this.ref,
    required this.text,
  });

  final String ref;
  final String text;

  factory HomeMeditationVerse.fromJson(Map<String, dynamic> json) {
    return HomeMeditationVerse(
      ref: json['ref'] as String,
      text: json['text'] as String,
    );
  }
}

/// Epoch for the home meditation day index (local calendar date).
final DateTime homeMeditationEpoch = DateTime(2026, 1, 1);

/// Days from [epoch] to the local calendar date of [now], floored.
///
/// Uses UTC date parts so daylight-saving transitions do not change the
/// day count. Dates before [epoch] yield a negative day count so modulo
/// still cycles.
int homeMeditationDayIndex(DateTime now, {DateTime? epoch}) {
  final start = epoch ?? homeMeditationEpoch;
  final today = DateTime.utc(now.year, now.month, now.day);
  final origin = DateTime.utc(start.year, start.month, start.day);
  return today.difference(origin).inDays;
}

/// Normalized list index for [now] plus a manual [offset].
///
/// Empty [verses] returns null. Day index and offset wrap with modulo;
/// negative days before the epoch still land on a valid entry.
int? homeMeditationIndex(
  List<HomeMeditationVerse> verses,
  DateTime now, {
  int offset = 0,
  DateTime? epoch,
}) {
  if (verses.isEmpty) return null;
  final day = homeMeditationDayIndex(now, epoch: epoch);
  final index = (day + offset) % verses.length;
  return index < 0 ? index + verses.length : index;
}

/// Verse for the local calendar day of [now] from [verses].
///
/// [offset] advances from the day's verse when the user rotates manually.
HomeMeditationVerse? homeMeditationForDay(
  List<HomeMeditationVerse> verses,
  DateTime now, {
  int offset = 0,
  DateTime? epoch,
}) {
  final index = homeMeditationIndex(
    verses,
    now,
    offset: offset,
    epoch: epoch,
  );
  if (index == null) return null;
  return verses[index];
}

/// Local calendar day key `yyyy-MM-dd` for offset persistence.
String homeMeditationDayKey(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
