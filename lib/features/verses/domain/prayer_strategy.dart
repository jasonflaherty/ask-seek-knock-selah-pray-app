/// A hidden lens for choosing scriptures. Not shown in the UI.
class PrayerStrategy {
  const PrayerStrategy({
    required this.id,
    required this.alwaysOn,
    required this.order,
    required this.triggers,
    required this.seedIds,
  });

  final String id;

  /// May contribute one verse even when no trigger word is present.
  final bool alwaysOn;

  final int order;

  /// Whole-word triggers, already stemmed the same way as a request.
  final Set<String> triggers;

  /// Verse ids in curated order. Every id exists in the bundled library.
  final List<String> seedIds;
}
