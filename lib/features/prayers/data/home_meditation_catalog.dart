import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/home_meditation.dart';

class HomeMeditationCatalog {
  HomeMeditationCatalog({
    this.assetPath = 'assets/verses/home_meditation.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<HomeMeditationVerse>? _cache;

  Future<List<HomeMeditationVerse>> load() async {
    if (_cache != null) return _cache!;

    final raw = await _bundle.loadString(assetPath);
    _cache = parse(raw);
    return _cache!;
  }

  /// Parses JSON without an asset bundle (for unit tests).
  static List<HomeMeditationVerse> parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['verses'] as List<dynamic>)
        .map((e) => HomeMeditationVerse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
