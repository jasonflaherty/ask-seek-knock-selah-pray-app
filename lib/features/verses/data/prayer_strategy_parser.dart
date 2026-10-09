import '../domain/prayer_strategy.dart';
import '../domain/verse.dart';
import 'text_normalizer.dart';

/// Builds selection strategies from JSON. [versesByRef] must use the same
/// reference strings as `verses.json`. Unknown seed refs are an error so a
/// typo cannot quietly offer the wrong passage.
List<PrayerStrategy> parsePrayerStrategies(
  Map<String, dynamic> json,
  Map<String, Verse> versesByRef,
) {
  final rawList = json['strategies'] as List<dynamic>? ?? const [];
  final strategies = <PrayerStrategy>[];

  for (final entry in rawList) {
    final map = entry as Map<String, dynamic>;
    final id = map['id'] as String;
    final refs = (map['seedRefs'] as List<dynamic>? ?? const []).cast<String>();
    final seedIds = <String>[];
    for (final ref in refs) {
      final verse = versesByRef[ref];
      if (verse == null) {
        throw FormatException('Strategy $id has unknown seed ref: $ref');
      }
      seedIds.add(verse.id);
    }
    if (seedIds.isEmpty) continue;

    final triggers = <String>{};
    for (final trigger in (map['triggers'] as List<dynamic>? ?? const [])) {
      final word = (trigger as String).trim();
      if (word.isEmpty || word.contains(RegExp(r'\s'))) {
        throw FormatException(
          'Strategy $id trigger must be one word: $trigger',
        );
      }
      final stem = TextNormalizer.stemToken(word);
      if (stem.isNotEmpty) triggers.add(stem);
    }

    strategies.add(
      PrayerStrategy(
        id: id,
        alwaysOn: map['alwaysOn'] as bool? ?? false,
        order: map['order'] as int? ?? 0,
        triggers: triggers,
        seedIds: seedIds,
      ),
    );
  }

  strategies.sort((a, b) => a.order.compareTo(b.order));
  return strategies;
}

/// Whole-word stems for strategy matching. Synonyms are not expanded, so
/// "son" does not appear inside "person".
Set<String> strategyQueryStems(String request) {
  final lower = request.toLowerCase().replaceAll(RegExp(r"[^\w\s'-]"), ' ');
  final stems = <String>{};
  for (final token in lower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty)) {
    if (TextNormalizer.stopwords.contains(token)) continue;
    final stem = TextNormalizer.stemToken(token);
    if (stem.isEmpty || TextNormalizer.stopwords.contains(stem)) continue;
    stems.add(stem);
  }
  return stems;
}
