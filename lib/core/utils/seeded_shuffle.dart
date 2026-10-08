import 'dart:math';

/// Deterministic order key for a prayer within a shuffle seed.
/// New prayers insert at their hashed position without reordering others.
int shuffleOrderKey(int seed, int prayerId) {
  // Mix seed and id into a stable 31-bit positive int.
  var x = seed ^ (prayerId * 0x9E3779B9);
  x = ((x >> 16) ^ x) * 0x45d9f3b;
  x = ((x >> 16) ^ x) * 0x45d9f3b;
  x = (x >> 16) ^ x;
  return x & 0x7fffffff;
}

/// Fisher–Yates shuffle with a seeded [Random]. Prefer [shuffleOrderKey]
/// for stable insertion of new items; this is kept for tests of seed equality.
List<T> seededShuffle<T>(List<T> items, int seed) {
  final copy = List<T>.from(items);
  final random = Random(seed);
  for (var i = copy.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final tmp = copy[i];
    copy[i] = copy[j];
    copy[j] = tmp;
  }
  return copy;
}

/// Daily seed: `yyyyMMdd * 1000 + reshuffleCount`.
int dailyShuffleSeed(DateTime day, int reshuffleCount) {
  final yyyymmdd = day.year * 10000 + day.month * 100 + day.day;
  return yyyymmdd * 1000 + reshuffleCount;
}
