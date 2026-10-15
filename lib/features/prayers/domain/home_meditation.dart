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

/// Verse for the local calendar day of [now] from [verses].
///
/// Empty [verses] returns null. Index wraps with modulo; negative days
/// before the epoch still land on a valid entry.
HomeMeditationVerse? homeMeditationForDay(
  List<HomeMeditationVerse> verses,
  DateTime now, {
  DateTime? epoch,
}) {
  if (verses.isEmpty) return null;
  final day = homeMeditationDayIndex(now, epoch: epoch);
  final index = day % verses.length;
  final normalized = index < 0 ? index + verses.length : index;
  return verses[normalized];
}
