import '../domain/sheet_row.dart';

/// Column headers for the Prayers tab (order matters).
const prayerSheetHeaders = [
  'syncId',
  'authorEmail',
  'name',
  'person',
  'request',
  'tags',
  'verseIds',
  'isAnswered',
  'answeredNote',
  'updatedAt',
  'deleted',
];

const verseSheetHeaders = ['id', 'ref', 'text', 'note'];

List<List<Object>> encodePrayerRows(List<SheetPrayerRow> rows) {
  return [
    prayerSheetHeaders,
    for (final r in rows)
      [
        r.syncId,
        r.authorEmail,
        r.name,
        r.person,
        r.request,
        r.tags.join('|'),
        r.verseIds.join('|'),
        r.isAnswered ? 'true' : 'false',
        r.answeredNote ?? '',
        r.updatedAt.toUtc().toIso8601String(),
        r.deleted ? 'true' : 'false',
      ],
  ];
}

List<SheetPrayerRow> decodePrayerRows(List<List<Object?>> values) {
  if (values.isEmpty) return const [];
  final header = values.first.map((c) => '$c'.trim().toLowerCase()).toList();
  int col(String name) => header.indexOf(name.toLowerCase());

  final syncI = col('syncid');
  final emailI = col('authoremail');
  final nameI = col('name');
  final personI = col('person');
  final requestI = col('request');
  final tagsI = col('tags');
  final verseI = col('verseids');
  final answeredI = col('isanswered');
  final noteI = col('answerednote');
  final updatedI = col('updatedat');
  final deletedI = col('deleted');

  if (syncI < 0 || nameI < 0 || requestI < 0) return const [];

  String at(List<Object?> row, int i) =>
      i >= 0 && i < row.length ? '${row[i] ?? ''}'.trim() : '';

  List<String> splitList(String raw) => raw.isEmpty
      ? const []
      : raw
          .split(RegExp(r'[|;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  final out = <SheetPrayerRow>[];
  for (var i = 1; i < values.length; i++) {
    final row = values[i];
    final syncId = at(row, syncI);
    if (syncId.isEmpty) continue;
    final updatedRaw = at(row, updatedI);
    final updatedAt = DateTime.tryParse(updatedRaw)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final answered = at(row, answeredI).toLowerCase();
    final deleted = at(row, deletedI).toLowerCase();
    final note = at(row, noteI);
    out.add(
      SheetPrayerRow(
        syncId: syncId,
        authorEmail: at(row, emailI).toLowerCase(),
        name: at(row, nameI),
        person: at(row, personI),
        request: at(row, requestI),
        tags: splitList(at(row, tagsI)),
        verseIds: splitList(at(row, verseI)),
        isAnswered: answered == 'true' || answered == '1',
        answeredNote: note.isEmpty ? null : note,
        updatedAt: updatedAt,
        deleted: deleted == 'true' || deleted == '1',
      ),
    );
  }
  return out;
}

List<List<Object>> encodeVerseRows(List<SheetVerseRow> rows) {
  return [
    verseSheetHeaders,
    for (final r in rows) [r.id, r.ref, r.text, r.note ?? ''],
  ];
}

List<SheetVerseRow> decodeVerseRows(List<List<Object?>> values) {
  if (values.isEmpty) return const [];
  final header = values.first.map((c) => '$c'.trim().toLowerCase()).toList();
  int col(String name) => header.indexOf(name.toLowerCase());
  final idI = col('id');
  final refI = col('ref');
  final textI = col('text');
  final noteI = col('note');
  if (idI < 0 || refI < 0 || textI < 0) return const [];

  String at(List<Object?> row, int i) =>
      i >= 0 && i < row.length ? '${row[i] ?? ''}'.trim() : '';

  final out = <SheetVerseRow>[];
  for (var i = 1; i < values.length; i++) {
    final row = values[i];
    final id = at(row, idI);
    if (id.isEmpty) continue;
    final note = at(row, noteI);
    out.add(
      SheetVerseRow(
        id: id,
        ref: at(row, refI),
        text: at(row, textI),
        note: note.isEmpty ? null : note,
      ),
    );
  }
  return out;
}
