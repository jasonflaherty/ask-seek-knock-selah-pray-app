import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/liturgical_prayer.dart';

class LiturgyCatalog {
  LiturgyCatalog({
    this.assetPath = 'assets/liturgy/collects.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<LiturgicalPrayer>? _cache;

  Future<List<LiturgicalPrayer>> load() async {
    if (_cache != null) return _cache!;

    final raw = await _bundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final prayers = (json['prayers'] as List<dynamic>)
        .map((e) => LiturgicalPrayer.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    _cache = prayers;
    return prayers;
  }

  /// Parses JSON without an asset bundle (for unit tests).
  static List<LiturgicalPrayer> parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['prayers'] as List<dynamic>)
        .map((e) => LiturgicalPrayer.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
