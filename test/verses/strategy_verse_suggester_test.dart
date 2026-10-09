import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/verses/data/keyword_verse_suggester.dart';
import 'package:selah/features/verses/data/prayer_strategy_parser.dart';
import 'package:selah/features/verses/data/strategy_verse_suggester.dart';
import 'package:selah/features/verses/data/text_normalizer.dart';
import 'package:selah/features/verses/data/verse_asset_loader.dart';
import 'package:selah/features/verses/domain/verse.dart';

VerseDataset _loadDataset() {
  final versesJson = jsonDecode(
    File('assets/verses/verses.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final synonymsJson = jsonDecode(
    File('assets/verses/synonyms.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final strategiesJson = jsonDecode(
    File('assets/verses/strategies.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final verses = (versesJson['verses'] as List)
      .map((e) => Verse.fromJson(e as Map<String, dynamic>))
      .toList();
  final synonyms = synonymsJson.map(
    (k, v) => MapEntry(k, (v as List).cast<String>()),
  );
  final strategies = parsePrayerStrategies(strategiesJson, {
    for (final verse in verses) verse.ref: verse,
  });

  return VerseDataset(
    translation: 'KJV',
    version: 1,
    verses: verses,
    synonyms: synonyms,
    strategies: strategies,
  );
}

void main() {
  late StrategyVerseSuggester suggester;

  setUpAll(() {
    final dataset = _loadDataset();
    suggester = StrategyVerseSuggester(
      KeywordVerseSuggester(dataset, TextNormalizer(dataset.synonyms)),
      dataset.strategies,
    );
  });

  test('every strategy seed resolves to a bundled verse', () {
    final dataset = _loadDataset();
    expect(dataset.strategies, hasLength(10));
    for (final strategy in dataset.strategies) {
      expect(strategy.seedIds, isNotEmpty);
      for (final id in strategy.seedIds) {
        expect(dataset.byId[id], isNotNull, reason: '${strategy.id} $id');
      }
    }
  });

  test('a request offers one promise and one thanksgiving verse', () async {
    final results = await suggester.suggest(
      'Please give me strength for this ordinary Tuesday',
    );
    final refs = results.map((v) => v.ref).join(' | ');
    expect(
      refs.contains('Jeremiah 33:3') ||
          refs.contains('1 John 5:14') ||
          refs.contains('John 15:7') ||
          refs.contains('Exodus 32:11'),
      isTrue,
      reason: refs,
    );
    expect(
      refs.contains('Philippians 4:6') ||
          refs.contains('1 Thessalonians 5:16') ||
          refs.contains('Psalm 50:15'),
      isTrue,
      reason: refs,
    );
  });

  test('praying for a son offers an intercession passage', () async {
    final results = await suggester.suggest(
      'My son is sick and in the hospital',
    );
    final refs = results.map((v) => v.ref).join(' | ');
    expect(
      refs.contains('Exodus 32:11') ||
          refs.contains('Genesis 18:23') ||
          refs.contains('Numbers 14:19'),
      isTrue,
      reason: refs,
    );
    expect(
      refs.contains('James 5:14') ||
          refs.contains('Psalm 103:2') ||
          refs.contains('Jeremiah 30:17'),
      isTrue,
      reason: refs,
    );
  });

  test('person and moment do not select intercession', () async {
    final results = await suggester.suggest('A person in the moment of fear');
    final refs = results.map((v) => v.ref).toList();
    expect(refs.any((r) => r.contains('Genesis 18:23')), isFalse);
    expect(refs.any((r) => r.contains('Numbers 14:19')), isFalse);
  });

  test('a long wait offers a persistence verse', () async {
    final results = await suggester.suggest(
      'I have been waiting for years and the prayer is unanswered',
    );
    final refs = results.map((v) => v.ref).join(' | ');
    expect(
      refs.contains('Luke 11:9') ||
          refs.contains('Romans 12:12') ||
          refs.contains('Psalm 27:14') ||
          refs.contains('Psalm 40:1') ||
          refs.contains('Galatians 6:9'),
      isTrue,
      reason: refs,
    );
  });

  test('guilt offers a clean-heart verse', () async {
    final results = await suggester.suggest(
      'I feel so guilty about what I did',
    );
    final refs = results.map((v) => v.ref).join(' | ');
    expect(
      refs.contains('1 John 1:9') ||
          refs.contains('Psalm 103:12') ||
          refs.contains('Isaiah 1:18') ||
          refs.contains('Psalm 51:10'),
      isTrue,
      reason: refs,
    );
  });

  test('a decision offers a stillness verse and a wisdom verse', () async {
    final results = await suggester.suggest('I need to make a big decision');
    final refs = results.map((v) => v.ref).join(' | ');
    expect(
      refs.contains('Psalm 46:10') ||
          refs.contains('Psalm 27:14') ||
          refs.contains('Psalm 37:7'),
      isTrue,
      reason: refs,
    );
    expect(
      refs.contains('Proverbs 3:5') || refs.contains('James 1:5'),
      isTrue,
      reason: refs,
    );
  });

  test('doubt offers an ask-and-trust verse', () async {
    final results = await suggester.suggest(
      'Help me believe and not doubt your answer',
    );
    final refs = results.map((v) => v.ref).join(' | ');
    expect(
      refs.contains('Mark 11:24') ||
          refs.contains('John 14:13') ||
          refs.contains('Hebrews 4:16') ||
          refs.contains('Hebrews 11:6') ||
          refs.contains('Matthew 7:7'),
      isTrue,
      reason: refs,
    );
  });

  test('common filler words do not select persistence', () async {
    final results = await suggester.suggest(
      'I am still yet to keep going again',
    );
    final refs = results.map((v) => v.ref).join(' | ');
    expect(refs.contains('Luke 11:9'), isFalse, reason: refs);
    expect(refs.contains('Romans 12:12'), isFalse, reason: refs);
    expect(refs.contains('Galatians 6:9'), isFalse, reason: refs);
  });

  test('results stay within the suggestion limit and are stable', () async {
    const query = 'Pray for our country and leaders';
    final a = await suggester.suggest(query);
    final b = await suggester.suggest(query);
    expect(a.length, lessThanOrEqualTo(6));
    expect(a.map((v) => v.id), b.map((v) => v.id));
    final refs = a.map((v) => v.ref).join(' | ');
    expect(refs.contains('2 Chronicles 7:14'), isTrue, reason: refs);
  });
}
