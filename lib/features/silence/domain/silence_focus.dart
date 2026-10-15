import '../../prayers/domain/prayer.dart';

/// Display line for a petition during silence — same rule as the prayer card.
String silenceFocusFor(Prayer prayer) =>
    prayer.hasPerson ? prayer.person : prayer.name;

/// Active petitions only, in repository order, as focus lines.
List<String> silenceFocusNames(List<Prayer> prayers) {
  return prayers
      .where((p) => !p.isAnswered)
      .map(silenceFocusFor)
      .where((name) => name.trim().isNotEmpty)
      .toList();
}
