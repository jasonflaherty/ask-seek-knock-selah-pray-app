import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/utils/seeded_shuffle.dart';

void main() {
  test('same seed yields same order', () {
    final items = [1, 2, 3, 4, 5, 6];
    expect(seededShuffle(items, 42), seededShuffle(items, 42));
  });

  test('different seed yields different order for lists > 3', () {
    final items = [1, 2, 3, 4, 5, 6];
    expect(seededShuffle(items, 1), isNot(seededShuffle(items, 2)));
  });

  test('shuffleOrderKey is stable for seed and id', () {
    expect(shuffleOrderKey(20240615000, 3), shuffleOrderKey(20240615000, 3));
    expect(shuffleOrderKey(20240615000, 3), isNot(shuffleOrderKey(20240615000, 4)));
  });

  test('dailyShuffleSeed encodes date and reshuffle count', () {
    expect(
      dailyShuffleSeed(DateTime(2024, 6, 15), 2),
      20240615 * 1000 + 2,
    );
  });
}
