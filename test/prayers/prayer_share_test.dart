import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/prayers/application/prayer_share.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/verses/domain/verse.dart';

void main() {
  test('plainText includes person, request, verses, and how praying', () {
    final now = DateTime(2024, 6, 15);
    const share = PrayerShare();
    final text = share.plainText(
      Prayer(
        id: 1,
        name: 'Mom’s healing',
        person: 'Mom',
        request: 'Please restore her strength.',
        isAnswered: false,
        createdAt: now,
        updatedAt: now,
        verseIds: const ['jer-33-3'],
      ),
      const [
        Verse(
          id: 'jer-33-3',
          ref: 'Jeremiah 33:3',
          text: 'Call unto me, and I will answer thee…',
          themes: ['prayer'],
          keywords: [],
          promiseType: PromiseType.explicitPromise,
          note: 'God invites us to call on Him.',
        ),
      ],
    );

    expect(text, contains('Mom’s healing'));
    expect(text, contains('For: Mom'));
    expect(text, contains('Please restore her strength.'));
    expect(text, contains('Jeremiah 33:3'));
    expect(text, contains('Call unto me'));
    expect(text, contains('How I’m praying'));
    expect(text, contains('revealed will'));
    expect(text, contains('Selah'));
  });
}
