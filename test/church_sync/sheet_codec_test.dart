import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/church_sync/application/church_sync_service.dart';
import 'package:selah/features/church_sync/data/sheet_codec.dart';
import 'package:selah/features/church_sync/domain/sheet_row.dart';

void main() {
  test('prayer rows round-trip through sheet codec', () {
    final row = SheetPrayerRow(
      syncId: 'abc-123',
      authorEmail: 'a@example.com',
      name: 'Healing',
      person: 'Mom',
      request: 'Please pray for recovery',
      tags: const ['health', 'family'],
      verseIds: const ['psalm-23-1', 'custom-1'],
      isAnswered: true,
      answeredNote: 'Praise God',
      updatedAt: DateTime.utc(2026, 3, 1, 12),
      deleted: false,
    );
    final encoded = encodePrayerRows([row]);
    final decoded = decodePrayerRows(encoded);
    expect(decoded, hasLength(1));
    expect(decoded.single.syncId, row.syncId);
    expect(decoded.single.person, 'Mom');
    expect(decoded.single.tags, ['health', 'family']);
    expect(decoded.single.isAnswered, isTrue);
    expect(decoded.single.answeredNote, 'Praise God');
    expect(decoded.single.fingerprint(), row.fingerprint());
  });

  test('parseSpreadsheetId accepts url and bare id', () {
    expect(
      parseSpreadsheetId(
        'https://docs.google.com/spreadsheets/d/1AbCdEfGhIjKlMnOpQrStUvWxYz/edit',
      ),
      '1AbCdEfGhIjKlMnOpQrStUvWxYz',
    );
    expect(
      parseSpreadsheetId('1AbCdEfGhIjKlMnOpQrStUvWxYz'),
      '1AbCdEfGhIjKlMnOpQrStUvWxYz',
    );
    expect(parseSpreadsheetId('not-a-sheet'), isNull);
  });
}
