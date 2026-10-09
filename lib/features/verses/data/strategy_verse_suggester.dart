import '../domain/prayer_strategy.dart';
import '../domain/verse.dart';
import '../domain/verse_suggester.dart';
import 'keyword_verse_suggester.dart';
import 'prayer_strategy_parser.dart';

/// Chooses scriptures by blending keyword rank with prayer-strategy seeds.
///
/// The user only sees verses. Each matching strategy contributes one seed
/// before a second verse is taken from that same strategy. Always-on
/// strategies may contribute even when the request has no trigger word.
/// The list is then ordered by keyword relevance.
class StrategyVerseSuggester implements VerseSuggester {
  StrategyVerseSuggester(this._keywords, this._strategies);

  final KeywordVerseSuggester _keywords;
  final List<PrayerStrategy> _strategies;

  @override
  Verse? byId(String id) => _keywords.byId(id);

  @override
  List<Verse> byIds(List<String> ids) => _keywords.byIds(ids);

  @override
  Future<List<Verse>> suggest(String request, {int limit = 6}) async {
    if (_strategies.isEmpty) {
      return _keywords.suggest(request, limit: limit);
    }

    final trimmed = request.trim();
    if (trimmed.length < 3) {
      return _keywords.suggest(request, limit: limit);
    }

    final ranked = _keywords.rank(trimmed);
    final scores = {for (final row in ranked) row.verse.id: row.score};
    final stems = strategyQueryStems(trimmed);

    final always = <PrayerStrategy>[];
    final situational = <({PrayerStrategy strategy, int hits})>[];
    for (final strategy in _strategies) {
      final hits = _hitCount(strategy, stems);
      if (strategy.alwaysOn) always.add(strategy);
      if (hits > 0) {
        situational.add((strategy: strategy, hits: hits));
      }
    }
    always.sort((a, b) => a.order.compareTo(b.order));
    situational.sort((a, b) {
      final byHits = b.hits.compareTo(a.hits);
      if (byHits != 0) return byHits;
      return a.strategy.order.compareTo(b.strategy.order);
    });

    final picked = <Verse>[];
    final usedVerses = <String>{};
    final usedStrategies = <String>{};

    void take(PrayerStrategy strategy) {
      if (picked.length >= limit) return;
      if (!usedStrategies.add(strategy.id)) return;
      final verse = _pickSeed(strategy, scores, usedVerses);
      if (verse == null) return;
      picked.add(verse);
      usedVerses.add(verse.id);
    }

    for (final strategy in always) {
      take(strategy);
    }
    for (final hit in situational) {
      take(hit.strategy);
    }
    for (final row in ranked) {
      if (picked.length >= limit) break;
      if (usedVerses.add(row.verse.id)) picked.add(row.verse);
    }

    if (picked.isEmpty) {
      return _keywords.suggest(request, limit: limit);
    }

    final insertedAt = <String, int>{
      for (var i = 0; i < picked.length; i++) picked[i].id: i,
    };
    picked.sort((a, b) {
      final byScore = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
      if (byScore != 0) return byScore;
      return insertedAt[a.id]!.compareTo(insertedAt[b.id]!);
    });
    return picked;
  }

  int _hitCount(PrayerStrategy strategy, Set<String> stems) {
    var hits = 0;
    for (final trigger in strategy.triggers) {
      if (stems.contains(trigger)) hits++;
    }
    return hits;
  }

  Verse? _pickSeed(
    PrayerStrategy strategy,
    Map<String, double> scores,
    Set<String> used,
  ) {
    final available = <Verse>[];
    for (final id in strategy.seedIds) {
      if (used.contains(id)) continue;
      final verse = _keywords.byId(id);
      if (verse != null) available.add(verse);
    }
    if (available.isEmpty) return null;

    available.sort((a, b) {
      final byScore = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
      if (byScore != 0) return byScore;
      return strategy.seedIds
          .indexOf(a.id)
          .compareTo(strategy.seedIds.indexOf(b.id));
    });
    return available.first;
  }
}
