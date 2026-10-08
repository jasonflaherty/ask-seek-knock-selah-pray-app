import 'dart:convert';
import 'dart:io';

const themes = {
  'provision',
  'healing',
  'fear',
  'anxiety',
  'peace',
  'guidance',
  'wisdom',
  'forgiveness',
  'mercy',
  'intercession',
  'protection',
  'strength',
  'comfort',
  'grief',
  'salvation',
  'family',
  'children',
  'marriage',
  'work',
  'nation',
  'faith',
  'hope',
  'perseverance',
  'prayer',
};

final idPattern = RegExp(r'^[a-z0-9]+(-\d+)+$');

void main() {
  final file = File('assets/verses/verses.json');
  if (!file.existsSync()) {
    stderr.writeln('Missing assets/verses/verses.json');
    exit(1);
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final verses = (json['verses'] as List).cast<Map<String, dynamic>>();
  final ids = <String>{};
  var errors = 0;

  void err(String msg) {
    stderr.writeln('ERROR: $msg');
    errors++;
  }

  if (verses.length < 100) {
    err('Need at least 100 verses, found ${verses.length}');
  }

  for (final v in verses) {
    final id = v['id'] as String? ?? '';
    final ref = v['ref'] as String? ?? '';
    final text = v['text'] as String? ?? '';
    final verseThemes = (v['themes'] as List?)?.cast<String>() ?? [];
    final keywords = (v['keywords'] as List?)?.cast<String>() ?? [];
    final promiseType = v['promiseType'] as String? ?? '';
    final note = v['note'] as String? ?? '';

    if (!idPattern.hasMatch(id)) err('Bad id format: $id');
    if (!ids.add(id)) err('Duplicate id: $id');
    if (text.trim().isEmpty) err('Empty text for $id');
    if (ref.trim().isEmpty) err('Empty ref for $id');
    if (note.trim().isEmpty) err('Empty note for $id');
    if (verseThemes.isEmpty || verseThemes.length > 4) {
      err('themes must be 1–4 for $id');
    }
    for (final t in verseThemes) {
      if (!themes.contains(t)) err('Invalid theme "$t" on $id');
    }
    if (keywords.length < 5 || keywords.length > 15) {
      err('keywords must be 5–15 for $id (got ${keywords.length})');
    }
    if (!{'explicit_promise', 'answered_prayer', 'character_of_god'}
        .contains(promiseType)) {
      err('Invalid promiseType on $id: $promiseType');
    }
  }

  if (errors > 0) {
    stderr.writeln('Validation failed with $errors error(s).');
    exit(1);
  }
  stdout.writeln('OK: ${verses.length} verses validated.');
}
