/// Protestant canon book names accepted for custom verses.
const bibleBooks = [
  'Genesis',
  'Exodus',
  'Leviticus',
  'Numbers',
  'Deuteronomy',
  'Joshua',
  'Judges',
  'Ruth',
  '1 Samuel',
  '2 Samuel',
  '1 Kings',
  '2 Kings',
  '1 Chronicles',
  '2 Chronicles',
  'Ezra',
  'Nehemiah',
  'Esther',
  'Job',
  'Psalm',
  'Psalms',
  'Proverbs',
  'Ecclesiastes',
  'Song of Solomon',
  'Song of Songs',
  'Isaiah',
  'Jeremiah',
  'Lamentations',
  'Ezekiel',
  'Daniel',
  'Hosea',
  'Joel',
  'Amos',
  'Obadiah',
  'Jonah',
  'Micah',
  'Nahum',
  'Habakkuk',
  'Zephaniah',
  'Haggai',
  'Zechariah',
  'Malachi',
  'Matthew',
  'Mark',
  'Luke',
  'John',
  'Acts',
  'Romans',
  '1 Corinthians',
  '2 Corinthians',
  'Galatians',
  'Ephesians',
  'Philippians',
  'Colossians',
  '1 Thessalonians',
  '2 Thessalonians',
  '1 Timothy',
  '2 Timothy',
  'Titus',
  'Philemon',
  'Hebrews',
  'James',
  '1 Peter',
  '2 Peter',
  '1 John',
  '2 John',
  '3 John',
  'Jude',
  'Revelation',
];

final _refPattern = RegExp(
  r'^(.+?)\s+(\d+)\s*:\s*(\d+)(?:\s*[-–—]\s*(\d+))?$',
  caseSensitive: false,
);

class BibleReferenceParse {
  const BibleReferenceParse({
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.normalized,
  });

  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String normalized;
}

/// Returns a normalized reference if [raw] looks like a real Bible citation.
BibleReferenceParse? parseBibleReference(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.isEmpty) return null;

  final match = _refPattern.firstMatch(trimmed);
  if (match == null) return null;

  final bookRaw = match.group(1)!.trim();
  final book = _matchBook(bookRaw);
  if (book == null) return null;

  final chapter = int.parse(match.group(2)!);
  final start = int.parse(match.group(3)!);
  final end = match.group(4) != null ? int.parse(match.group(4)!) : start;
  if (chapter < 1 || start < 1 || end < start) return null;

  final displayBook = book == 'Psalms' ? 'Psalm' : book;
  final normalized = end == start
      ? '$displayBook $chapter:$start'
      : '$displayBook $chapter:$start–$end';

  return BibleReferenceParse(
    book: displayBook,
    chapter: chapter,
    startVerse: start,
    endVerse: end,
    normalized: normalized,
  );
}

String? _matchBook(String input) {
  final lower = input.toLowerCase();
  for (final book in bibleBooks) {
    if (book.toLowerCase() == lower) return book;
  }
  // Common shorthand
  const aliases = {
    'ps': 'Psalm',
    'psa': 'Psalm',
    'gen': 'Genesis',
    'exo': 'Exodus',
    'ex': 'Exodus',
    'matt': 'Matthew',
    'mt': 'Matthew',
    'mk': 'Mark',
    'lk': 'Luke',
    'jn': 'John',
    'rom': 'Romans',
    'phil': 'Philippians',
    'php': 'Philippians',
    'heb': 'Hebrews',
    'jas': 'James',
    'jam': 'James',
    'rev': 'Revelation',
    '1 jn': '1 John',
    '2 jn': '2 John',
    '3 jn': '3 John',
    '1 pet': '1 Peter',
    '2 pet': '2 Peter',
    '1 cor': '1 Corinthians',
    '2 cor': '2 Corinthians',
    '1 thess': '1 Thessalonians',
    '2 thess': '2 Thessalonians',
    '1 tim': '1 Timothy',
    '2 tim': '2 Timothy',
    '1 sam': '1 Samuel',
    '2 sam': '2 Samuel',
    '1 ki': '1 Kings',
    '2 ki': '2 Kings',
    '1 chr': '1 Chronicles',
    '2 chr': '2 Chronicles',
  };
  return aliases[lower];
}

bool isCustomVerseId(String id) => id.startsWith('custom-');
