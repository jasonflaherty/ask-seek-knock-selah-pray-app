import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/clock.dart';
import '../domain/bible_reference.dart';
import '../domain/custom_verse_repository.dart';
import '../domain/verse.dart';

class DriftCustomVerseRepository implements CustomVerseRepository {
  DriftCustomVerseRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Verse> addCustom({
    required String ref,
    required String text,
    String? note,
  }) async {
    final parsed = parseBibleReference(ref);
    if (parsed == null) {
      throw ArgumentError('Enter a valid Bible reference (e.g. John 14:13–14).');
    }
    final body = text.trim();
    if (body.length < 12) {
      throw ArgumentError('Paste the exact Scripture wording of the promise.');
    }

    final id =
        'custom-${_clock.now().microsecondsSinceEpoch.toRadixString(16)}';
    final cleanedNote = note?.trim();
    await _db.into(_db.customVerses).insert(
          CustomVersesCompanion.insert(
            id: id,
            ref: parsed.normalized,
            body: body,
            note: Value(
              (cleanedNote == null || cleanedNote.isEmpty) ? null : cleanedNote,
            ),
            createdAt: _clock.now(),
          ),
        );
    return _toVerse(
      id: id,
      ref: parsed.normalized,
      text: body,
      note: cleanedNote,
    );
  }

  @override
  Future<Verse> importCustom({
    required String id,
    required String ref,
    required String text,
    String? note,
  }) async {
    if (!isCustomVerseId(id)) {
      throw ArgumentError('Custom verse id must start with custom-');
    }
    final parsed = parseBibleReference(ref);
    if (parsed == null) {
      throw ArgumentError('Enter a valid Bible reference (e.g. John 14:13–14).');
    }
    final body = text.trim();
    if (body.length < 12) {
      throw ArgumentError('Paste the exact Scripture wording of the promise.');
    }
    final cleanedNote = note?.trim();
    await _db.into(_db.customVerses).insertOnConflictUpdate(
          CustomVersesCompanion.insert(
            id: id,
            ref: parsed.normalized,
            body: body,
            note: Value(
              (cleanedNote == null || cleanedNote.isEmpty) ? null : cleanedNote,
            ),
            createdAt: _clock.now(),
          ),
        );
    return _toVerse(
      id: id,
      ref: parsed.normalized,
      text: body,
      note: cleanedNote,
    );
  }

  @override
  Future<Verse?> getById(String id) async {
    if (!isCustomVerseId(id)) return null;
    final row = await (_db.select(_db.customVerses)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _toVerse(
      id: row.id,
      ref: row.ref,
      text: row.body,
      note: row.note,
    );
  }

  @override
  Future<List<Verse>> getByIds(List<String> ids) async {
    final customIds = ids.where(isCustomVerseId).toList();
    if (customIds.isEmpty) return const [];
    final rows = await (_db.select(_db.customVerses)
          ..where((t) => t.id.isIn(customIds)))
        .get();
    final byId = {
      for (final row in rows)
        row.id: _toVerse(
          id: row.id,
          ref: row.ref,
          text: row.body,
          note: row.note,
        ),
    };
    return [
      for (final id in customIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Stream<List<Verse>> watchAll() {
    return (_db.select(_db.customVerses)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              _toVerse(
                id: row.id,
                ref: row.ref,
                text: row.body,
                note: row.note,
              ),
          ],
        );
  }

  Verse _toVerse({
    required String id,
    required String ref,
    required String text,
    String? note,
  }) {
    return Verse(
      id: id,
      ref: ref,
      text: text,
      themes: const ['prayer'],
      keywords: const [],
      promiseType: PromiseType.explicitPromise,
      note: (note == null || note.isEmpty)
          ? 'Added by you — pray God’s Word as He has spoken it.'
          : note,
    );
  }
}
