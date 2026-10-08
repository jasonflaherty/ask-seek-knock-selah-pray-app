import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/utils/seeded_shuffle.dart';
import 'package:selah/features/prayers/application/prayer_list_notifier.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/prayers/domain/sort_mode.dart';

Prayer _p({
  required int id,
  required String name,
  DateTime? createdAt,
  List<String> tags = const [],
}) {
  final created = createdAt ?? DateTime(2024, 1, id);
  return Prayer(
    id: id,
    name: name,
    request: 'request $id',
    isAnswered: false,
    createdAt: created,
    updatedAt: created,
    tags: tags,
  );
}

void main() {
  final prayers = [
    _p(id: 1, name: 'Charlie', createdAt: DateTime(2024, 1, 1), tags: ['work']),
    _p(id: 2, name: 'alice', createdAt: DateTime(2024, 1, 3), tags: ['Family']),
    _p(id: 3, name: 'Bob', createdAt: DateTime(2024, 1, 2)),
    _p(id: 4, name: 'Dana', createdAt: DateTime(2024, 1, 4), tags: ['family']),
  ];

  test('newest sort', () {
    final sorted = sortPrayers(prayers, mode: SortMode.newest, seed: 0);
    expect(sorted.map((p) => p.id), [4, 2, 3, 1]);
  });

  test('oldest sort', () {
    final sorted = sortPrayers(prayers, mode: SortMode.oldest, seed: 0);
    expect(sorted.map((p) => p.id), [1, 3, 2, 4]);
  });

  test('name sort is case-insensitive', () {
    final sorted = sortPrayers(prayers, mode: SortMode.name, seed: 0);
    expect(sorted.map((p) => p.name), ['alice', 'Bob', 'Charlie', 'Dana']);
  });

  test('tag sort groups by primary tag with untagged last', () {
    final sorted = sortPrayers(prayers, mode: SortMode.tag, seed: 0);
    expect(sorted.map((p) => p.id), [4, 2, 1, 3]);
  });

  test('shuffle is deterministic for a seed', () {
    final seed = dailyShuffleSeed(DateTime(2024, 6, 15), 0);
    final a = sortPrayers(prayers, mode: SortMode.shuffle, seed: seed);
    final b = sortPrayers(prayers, mode: SortMode.shuffle, seed: seed);
    expect(a.map((p) => p.id), b.map((p) => p.id));
  });

  test('new prayer inserts without reordering others in shuffle', () {
    final seed = dailyShuffleSeed(DateTime(2024, 6, 15), 0);
    final before = sortPrayers(prayers, mode: SortMode.shuffle, seed: seed)
        .map((p) => p.id)
        .toList();
    final withNew = [
      ...prayers,
      _p(id: 99, name: 'New', createdAt: DateTime(2024, 6, 15)),
    ];
    final after = sortPrayers(withNew, mode: SortMode.shuffle, seed: seed)
        .map((p) => p.id)
        .toList();
    after.remove(99);
    expect(after, before);
  });
}
