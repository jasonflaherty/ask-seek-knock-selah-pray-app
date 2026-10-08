import 'dart:math' as math;

import '../domain/verse.dart';
import '../domain/verse_suggester.dart';
import 'text_normalizer.dart';
import 'verse_asset_loader.dart';

class _IndexedVerse {
  _IndexedVerse({
    required this.verse,
    required this.tokenWeights,
    required this.length,
    required this.datasetIndex,
  });

  final Verse verse;
  final Map<String, double> tokenWeights;
  final double length;
  final int datasetIndex;
}

class KeywordVerseSuggester implements VerseSuggester {
  KeywordVerseSuggester(this._dataset, this._normalizer) {
    _byId = {for (final v in _dataset.verses) v.id: v};
    _index = [
      for (var i = 0; i < _dataset.verses.length; i++)
        _buildIndex(_dataset.verses[i], i),
    ];
    _docFreq = {};
    for (final doc in _index) {
      for (final token in doc.tokenWeights.keys) {
        _docFreq[token] = (_docFreq[token] ?? 0) + 1;
      }
    }
    _avgLen = _index.isEmpty
        ? 1.0
        : _index.map((d) => d.length).reduce((a, b) => a + b) / _index.length;
  }

  static const fallbackIds = [
    'jer-33-3',
    'phi-4-6-7',
    '1jo-5-14-15',
    'psa-145-18-19',
    'mat-7-7-8',
    'isa-41-10',
  ];

  final VerseDataset _dataset;
  final TextNormalizer _normalizer;
  late final Map<String, Verse> _byId;
  late final List<_IndexedVerse> _index;
  late final Map<String, int> _docFreq;
  late final double _avgLen;

  @override
  Verse? byId(String id) => _byId[id];

  @override
  List<Verse> byIds(List<String> ids) {
    return [
      for (final id in ids)
        if (_byId[id] != null) _byId[id]!,
    ];
  }

  @override
  Future<List<Verse>> suggest(String request, {int limit = 6}) async {
    final trimmed = request.trim();
    if (trimmed.length < 3) {
      return _fallback(limit);
    }

    final query = _normalizer.tokenize(trimmed);
    if (query.isEmpty) {
      return _fallback(limit);
    }

    final scored = <({_IndexedVerse doc, double score})>[];
    for (final doc in _index) {
      final raw = _bm25(query, doc);
      if (raw > 0) {
        scored.add((
          doc: doc,
          score: raw * _typeBoost(doc.verse.promiseType),
        ));
      }
    }

    if (scored.isEmpty) {
      return _fallback(limit);
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.doc.datasetIndex.compareTo(b.doc.datasetIndex);
    });

    return scored.take(limit).map((e) => e.doc.verse).toList();
  }

  List<Verse> _fallback(int limit) {
    final verses = <Verse>[];
    for (final id in fallbackIds) {
      final v = _byId[id];
      if (v != null) verses.add(v);
      if (verses.length >= limit) break;
    }
    if (verses.isEmpty) {
      return _dataset.verses.take(limit).toList();
    }
    return verses;
  }

  double _bm25(Map<String, double> query, _IndexedVerse doc) {
    const k1 = 1.2;
    const b = 0.75;
    var score = 0.0;
    final n = _index.length;
    for (final entry in query.entries) {
      final token = entry.key;
      final qWeight = entry.value;
      final tf = doc.tokenWeights[token];
      if (tf == null || tf <= 0) continue;
      final df = _docFreq[token] ?? 0;
      final idf = math.log((n - df + 0.5) / (df + 0.5) + 1);
      final denom = tf + k1 * (1 - b + b * (doc.length / _avgLen));
      score += qWeight * idf * ((tf * (k1 + 1)) / denom);
    }
    return score;
  }

  double _typeBoost(PromiseType type) => switch (type) {
        PromiseType.explicitPromise => 1.15,
        PromiseType.answeredPrayer => 1.1,
        PromiseType.characterOfGod => 1.0,
      };

  _IndexedVerse _buildIndex(Verse verse, int index) {
    final weights = <String, double>{};

    void addText(String text, double fieldWeight) {
      final tokens = _normalizer.tokenize(text);
      for (final e in tokens.entries) {
        weights[e.key] = (weights[e.key] ?? 0) + e.value * fieldWeight;
      }
    }

    for (final kw in verse.keywords) {
      addText(kw, 1.0);
    }
    for (final theme in verse.themes) {
      addText(theme, 2.0);
    }
    addText(verse.note, 0.5);
    addText(verse.ref, 0.25);

    final length = weights.values.fold<double>(0, (a, b) => a + b);
    return _IndexedVerse(
      verse: verse,
      tokenWeights: weights,
      length: length <= 0 ? 1 : length,
      datasetIndex: index,
    );
  }
}
