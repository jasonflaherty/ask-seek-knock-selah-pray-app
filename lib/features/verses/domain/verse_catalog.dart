import 'bible_reference.dart';
import 'custom_verse_repository.dart';
import 'verse.dart';
import 'verse_suggester.dart';

/// Resolves bundled and user-added verses for display and selection.
class VerseCatalog {
  VerseCatalog({
    required VerseSuggester suggester,
    required CustomVerseRepository custom,
  })  : _suggester = suggester,
        _custom = custom;

  final VerseSuggester _suggester;
  final CustomVerseRepository _custom;

  VerseSuggester get suggester => _suggester;

  Future<Verse?> byId(String id) async {
    if (isCustomVerseId(id)) {
      return _custom.getById(id);
    }
    return _suggester.byId(id);
  }

  Future<List<Verse>> byIds(List<String> ids) async {
    final result = <Verse>[];
    final missingCustom = <String>[];
    for (final id in ids) {
      if (isCustomVerseId(id)) {
        missingCustom.add(id);
      } else {
        final v = _suggester.byId(id);
        if (v != null) result.add(v);
      }
    }
    if (missingCustom.isNotEmpty) {
      final customs = await _custom.getByIds(missingCustom);
      final byId = {for (final v in customs) v.id: v};
      for (final id in missingCustom) {
        final v = byId[id];
        if (v != null) result.add(v);
      }
    }
    // Preserve selection order from [ids].
    final ordered = <Verse>[];
    final map = {for (final v in result) v.id: v};
    for (final id in ids) {
      final v = map[id];
      if (v != null) ordered.add(v);
    }
    return ordered;
  }

  Future<Verse> addCustom({
    required String ref,
    required String text,
    String? note,
  }) {
    return _custom.addCustom(ref: ref, text: text, note: note);
  }
}
