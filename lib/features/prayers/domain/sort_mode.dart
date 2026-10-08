enum SortMode {
  shuffle,
  newest,
  oldest,
  name,
  tag,
}

extension SortModeX on SortMode {
  String get storageKey => name;

  static SortMode fromStorage(String? value) {
    return SortMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => SortMode.shuffle,
    );
  }

  String get label => switch (this) {
        SortMode.shuffle => 'Shuffle',
        SortMode.newest => 'Newest',
        SortMode.oldest => 'Oldest',
        SortMode.name => 'Name',
        SortMode.tag => 'Tag',
      };
}
