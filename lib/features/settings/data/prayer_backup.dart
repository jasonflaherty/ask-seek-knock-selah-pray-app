import 'dart:convert';

import '../../prayers/domain/prayer.dart';
import '../../prayers/domain/prayer_repository.dart';

/// Portable prayer row for JSON/CSV backup (no local IDs or events).
class PrayerBackupRow {
  const PrayerBackupRow({
    required this.name,
    this.person = '',
    required this.request,
    this.tags = const [],
    this.verseIds = const [],
    this.isAnswered = false,
    this.answeredNote,
  });

  final String name;
  final String person;
  final String request;
  final List<String> tags;
  final List<String> verseIds;
  final bool isAnswered;
  final String? answeredNote;

  factory PrayerBackupRow.fromPrayer(Prayer p) => PrayerBackupRow(
        name: p.name,
        person: p.person,
        request: p.request,
        tags: List.of(p.tags),
        verseIds: List.of(p.verseIds),
        isAnswered: p.isAnswered,
        answeredNote: p.answeredNote,
      );

  NewPrayer toNewPrayer() => NewPrayer(
        name: name,
        person: person,
        request: request,
        tags: tags,
        verseIds: verseIds,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'person': person,
        'request': request,
        'tags': tags,
        'verseIds': verseIds,
        'isAnswered': isAnswered,
        if (answeredNote != null) 'answeredNote': answeredNote,
      };

  factory PrayerBackupRow.fromJson(Map<String, dynamic> json) {
    return PrayerBackupRow(
      name: (json['name'] as String? ?? '').trim(),
      person: (json['person'] as String? ?? '').trim(),
      request: (json['request'] as String? ?? '').trim(),
      tags: _stringList(json['tags']),
      verseIds: _stringList(json['verseIds'] ?? json['verse_ids']),
      isAnswered: json['isAnswered'] == true ||
          json['is_answered'] == true ||
          json['isAnswered'] == 'true' ||
          json['is_answered'] == 'true',
      answeredNote: (json['answeredNote'] ?? json['answered_note']) as String?,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[|;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

class PrayerBackupCodec {
  static const jsonVersion = 1;

  String encodeJson(List<PrayerBackupRow> rows, {DateTime? exportedAt}) {
    final payload = {
      'version': jsonVersion,
      'exportedAt': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
      'prayers': rows.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  List<PrayerBackupRow> decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup JSON must be an object');
    }
    final list = decoded['prayers'];
    if (list is! List) {
      throw const FormatException('Backup JSON missing prayers array');
    }
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) PrayerBackupRow.fromJson(item),
    ].where((r) => r.name.isNotEmpty && r.request.isNotEmpty).toList();
  }

  String encodeCsv(List<PrayerBackupRow> rows) {
    final buf = StringBuffer()
      ..writeln(
        _csvLine([
          'name',
          'person',
          'request',
          'tags',
          'verseIds',
          'isAnswered',
          'answeredNote',
        ]),
      );
    for (final r in rows) {
      buf.writeln(
        _csvLine([
          r.name,
          r.person,
          r.request,
          r.tags.join('|'),
          r.verseIds.join('|'),
          r.isAnswered ? 'true' : 'false',
          r.answeredNote ?? '',
        ]),
      );
    }
    return buf.toString();
  }

  List<PrayerBackupRow> decodeCsv(String raw) {
    final rows = _parseCsv(raw);
    if (rows.isEmpty) return const [];

    final header = rows.first.map((c) => c.trim().toLowerCase()).toList();
    int col(String name) {
      final i = header.indexOf(name.toLowerCase());
      return i;
    }

    final nameI = col('name');
    final personI = col('person');
    final requestI = col('request');
    final tagsI = col('tags');
    final verseI = col('verseids');
    final answeredI = col('isanswered');
    final noteI = col('answerednote');

    if (nameI < 0 || requestI < 0) {
      throw const FormatException('CSV needs name and request columns');
    }

    final out = <PrayerBackupRow>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      String at(int index) =>
          index >= 0 && index < row.length ? row[index].trim() : '';

      final name = at(nameI);
      final request = at(requestI);
      if (name.isEmpty || request.isEmpty) continue;

      out.add(
        PrayerBackupRow(
          name: name,
          person: at(personI),
          request: request,
          tags: PrayerBackupRow._stringList(at(tagsI)),
          verseIds: PrayerBackupRow._stringList(at(verseI)),
          isAnswered: at(answeredI).toLowerCase() == 'true' || at(answeredI) == '1',
          answeredNote: () {
            final n = at(noteI);
            return n.isEmpty ? null : n;
          }(),
        ),
      );
    }
    return out;
  }

  static String _csvLine(List<String> fields) =>
      fields.map(_escapeCsv).join(',');

  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Minimal RFC4180-ish CSV parser.
  static List<List<String>> _parseCsv(String raw) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (ch == '\n') {
        row.add(field.toString());
        field = StringBuffer();
        if (row.any((c) => c.trim().isNotEmpty)) {
          rows.add(row);
        }
        row = [];
      } else {
        field.write(ch);
      }
    }
    row.add(field.toString());
    if (row.any((c) => c.trim().isNotEmpty)) {
      rows.add(row);
    }
    return rows;
  }
}

class PrayerBackupService {
  PrayerBackupService(this._repo, {PrayerBackupCodec? codec})
      : _codec = codec ?? PrayerBackupCodec();

  final PrayerRepository _repo;
  final PrayerBackupCodec _codec;

  Future<List<PrayerBackupRow>> collect() async {
    final prayers = await _repo.watchPrayers(filter: AnswerFilter.all).first;
    return prayers.map(PrayerBackupRow.fromPrayer).toList();
  }

  Future<String> exportJson() async {
    final rows = await collect();
    return _codec.encodeJson(rows);
  }

  Future<String> exportCsv() async {
    final rows = await collect();
    return _codec.encodeCsv(rows);
  }

  /// Imports rows as new prayers. Returns how many were created.
  Future<int> importRows(List<PrayerBackupRow> rows) async {
    var count = 0;
    for (final row in rows) {
      if (row.name.trim().isEmpty || row.request.trim().isEmpty) continue;
      final id = await _repo.createPrayer(row.toNewPrayer());
      if (row.isAnswered) {
        await _repo.setAnswered(
          id,
          answered: true,
          note: row.answeredNote,
        );
      }
      count++;
    }
    return count;
  }

  Future<int> importJson(String raw) => importRows(_codec.decodeJson(raw));

  Future<int> importCsv(String raw) => importRows(_codec.decodeCsv(raw));
}
