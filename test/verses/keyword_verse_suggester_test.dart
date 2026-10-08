import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/verses/data/keyword_verse_suggester.dart';
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

  final verses = (versesJson['verses'] as List)
      .map((e) => Verse.fromJson(e as Map<String, dynamic>))
      .toList();
  final synonyms = synonymsJson.map(
    (k, v) => MapEntry(k, (v as List).cast<String>()),
  );

  return VerseDataset(
    translation: 'KJV',
    version: 1,
    verses: verses,
    synonyms: synonyms,
  );
}

void main() {
  late KeywordVerseSuggester suggester;

  setUpAll(() {
    final dataset = _loadDataset();
    suggester = KeywordVerseSuggester(dataset, TextNormalizer(dataset.synonyms));
  });

  test('dataset has at least 100 verses', () {
    expect(_loadDataset().verses.length, greaterThanOrEqualTo(100));
  });

  test('short input returns fallback set', () async {
    final results = await suggester.suggest('asdf');
    final refs = results.map((v) => v.ref).toList();
    expect(refs.any((r) => r.contains('Jeremiah 33:3')), isTrue);
  });

  test('empty input returns fallback', () async {
    final results = await suggester.suggest('ab');
    expect(results, isNotEmpty);
  });

  test('determinism', () async {
    const q = 'I need wisdom for a decision at work';
    final a = await suggester.suggest(q);
    final b = await suggester.suggest(q);
    expect(a.map((v) => v.id), b.map((v) => v.id));
  });

  group('fixture matching (section 11.2)', () {
    Future<void> expectTop6(String input, List<String> refSubstrings) async {
      final results = await suggester.suggest(input);
      expect(results.length, lessThanOrEqualTo(6));
      final joined = results.map((v) => v.ref).join(' | ');
      expect(
        refSubstrings.any(joined.contains),
        isTrue,
        reason: 'Expected one of $refSubstrings in top 6: $joined',
      );
    }

    test('sick son', () async {
      await expectTop6(
        'My son is sick and in the hospital',
        ['James 5:14', 'Psalm 103:2', 'Jeremiah 30:17'],
      );
    });

    test('lost job', () async {
      await expectTop6(
        "I lost my job and I'm worried about bills",
        ['Philippians 4:19', 'Matthew 6:31'],
      );
    });

    test('decision', () async {
      await expectTop6(
        'I need to make a big decision',
        ['Proverbs 3:5', 'James 1:5'],
      );
    });

    test('country', () async {
      await expectTop6(
        'Pray for our country and leaders',
        ['2 Chronicles 7:14'],
      );
    });

    test('unsaved husband', () async {
      await expectTop6(
        "My husband doesn't know Jesus",
        ['Acts 16:31', '2 Peter 3:9'],
      );
    });

    test('guilt', () async {
      await expectTop6(
        'I feel so guilty about what I did',
        ['1 John 1:9', 'Psalm 103:12'],
      );
    });

    test('grief', () async {
      await expectTop6(
        'My mom died last month',
        ['Psalm 34:18', 'Revelation 21:4'],
      );
    });

    test('asdf fallback', () async {
      final results = await suggester.suggest('asdf');
      final ids = results.map((v) => v.id).toSet();
      expect(ids.intersection(KeywordVerseSuggester.fallbackIds.toSet()), isNotEmpty);
    });
  });
}
