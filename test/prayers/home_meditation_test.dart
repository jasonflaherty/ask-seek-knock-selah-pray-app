import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/prayers/data/home_meditation_catalog.dart';
import 'package:selah/features/prayers/domain/home_meditation.dart';

void main() {
  late final verses = HomeMeditationCatalog.parse(
    File('assets/verses/home_meditation.json').readAsStringSync(),
  );

  test('loads a large interleaved holiness and Spirit list', () {
    expect(verses.length, greaterThanOrEqualTo(70));
    expect(verses.first.ref, 'Habakkuk 2:20');
    expect(verses[1].ref, 'Galatians 5:16');
    expect(
      verses.any((v) => v.ref == 'Proverbs 3:5–6'),
      isTrue,
    );
  });

  test('spot-checks Habakkuk and Proverbs against KJV source wording', () {
    final habakkuk = verses.firstWhere((v) => v.ref == 'Habakkuk 2:20');
    expect(
      habakkuk.text,
      'But the Lord is in his holy temple: let all the earth keep silence before him.',
    );

    final proverbs = verses.firstWhere((v) => v.ref == 'Proverbs 3:5–6');
    expect(
      proverbs.text,
      'Trust in the Lord with all thine heart; and lean not unto thine own '
      'understanding. In all thy ways acknowledge him, and he shall direct thy paths.',
    );
  });

  test('selects index 0 on the epoch day', () {
    final verse = homeMeditationForDay(verses, DateTime(2026, 1, 1, 15, 30));
    expect(verse?.ref, verses[0].ref);
  });

  test('advances one verse on the next calendar day', () {
    final day0 = homeMeditationForDay(verses, DateTime(2026, 1, 1));
    final day1 = homeMeditationForDay(verses, DateTime(2026, 1, 2));
    expect(day0?.ref, verses[0].ref);
    expect(day1?.ref, verses[1].ref);
  });

  test('wraps past the end of the list', () {
    // Calendar arithmetic avoids DST skew from Duration(days: …).
    final day = homeMeditationForDay(
      verses,
      DateTime(2026, 1, 1 + verses.length),
    );
    expect(day?.ref, verses[0].ref);
  });

  test('dates before the epoch still cycle into the list', () {
    final day = homeMeditationForDay(verses, DateTime(2025, 12, 31));
    expect(day, isNotNull);
    expect(day!.ref, verses[verses.length - 1].ref);
  });

  test('empty list returns null', () {
    expect(homeMeditationForDay(const [], DateTime(2026, 1, 1)), isNull);
  });

  test('day index ignores time of day', () {
    expect(
      homeMeditationDayIndex(DateTime(2026, 1, 3, 0, 0)),
      homeMeditationDayIndex(DateTime(2026, 1, 3, 23, 59)),
    );
  });

  test('manual offset advances from the day verse and wraps', () {
    final day = DateTime(2026, 1, 1);
    expect(
      homeMeditationForDay(verses, day, offset: 1)?.ref,
      verses[1].ref,
    );
    expect(
      homeMeditationForDay(verses, day, offset: verses.length)?.ref,
      verses[0].ref,
    );
  });

  test('day key is yyyy-MM-dd', () {
    expect(homeMeditationDayKey(DateTime(2026, 3, 9)), '2026-03-09');
  });
}
