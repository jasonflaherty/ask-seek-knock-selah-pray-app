import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/verses/data/text_normalizer.dart';

void main() {
  final normalizer = TextNormalizer({
    'sick': ['healing', 'illness', 'disease'],
    'worried': ['anxiety', 'fear', 'peace'],
    'job': ['work', 'provision'],
  });

  test('removes stopwords and punctuation', () {
    final tokens = normalizer.tokenize("I'm so worried about the bills!!!");
    expect(tokens.containsKey('worried') || tokens.containsKey('worri'), isTrue);
    expect(tokens.containsKey('the'), isFalse);
    expect(tokens.containsKey('about'), isFalse);
  });

  test('stems common endings', () {
    expect(TextNormalizer.stemToken('praying'), 'pray');
    expect(TextNormalizer.stemToken('healed'), 'heal');
    expect(TextNormalizer.stemToken('quickly'), 'quick');
    expect(TextNormalizer.stemToken('bills'), 'bill');
  });

  test('expands synonyms at lower weight', () {
    final tokens = normalizer.tokenize('My son is sick');
    expect(tokens['sick'] ?? tokens['sic'], greaterThan(0));
    expect(tokens['healing'] ?? tokens['heal'], closeTo(0.6, 0.01));
  });
}
