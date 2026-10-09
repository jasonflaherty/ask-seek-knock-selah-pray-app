import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/prayer_strategy.dart';
import '../domain/verse.dart';
import 'prayer_strategy_parser.dart';
import 'text_normalizer.dart';

class VerseDataset {
  VerseDataset({
    required this.translation,
    required this.version,
    required this.verses,
    required this.synonyms,
    this.strategies = const [],
  });

  final String translation;
  final int version;
  final List<Verse> verses;
  final Map<String, List<String>> synonyms;
  final List<PrayerStrategy> strategies;

  Map<String, Verse> get byId => {for (final v in verses) v.id: v};
}

class VerseAssetLoader {
  VerseAssetLoader({
    this.versesAsset = 'assets/verses/verses.json',
    this.synonymsAsset = 'assets/verses/synonyms.json',
    this.strategiesAsset = 'assets/verses/strategies.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String versesAsset;
  final String synonymsAsset;
  final String strategiesAsset;
  final AssetBundle _bundle;

  VerseDataset? _cache;

  Future<VerseDataset> load() async {
    if (_cache != null) return _cache!;

    final versesRaw = await _bundle.loadString(versesAsset);
    final synonymsRaw = await _bundle.loadString(synonymsAsset);
    final strategiesRaw = await _bundle.loadString(strategiesAsset);
    final versesJson = jsonDecode(versesRaw) as Map<String, dynamic>;
    final synonymsJson = jsonDecode(synonymsRaw) as Map<String, dynamic>;
    final strategiesJson = jsonDecode(strategiesRaw) as Map<String, dynamic>;

    final verses = (versesJson['verses'] as List<dynamic>)
        .map((e) => Verse.fromJson(e as Map<String, dynamic>))
        .toList();

    final synonyms = synonymsJson.map(
      (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
    );

    _cache = VerseDataset(
      translation: versesJson['translation'] as String? ?? 'KJV',
      version: versesJson['version'] as int? ?? 1,
      verses: verses,
      synonyms: synonyms,
      strategies: parsePrayerStrategies(strategiesJson, {
        for (final verse in verses) verse.ref: verse,
      }),
    );
    return _cache!;
  }

  TextNormalizer createNormalizer(VerseDataset dataset) {
    return TextNormalizer(dataset.synonyms);
  }
}
