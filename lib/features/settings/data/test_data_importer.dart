import 'package:shared_preferences/shared_preferences.dart';

import '../../prayers/domain/prayer.dart';
import '../../prayers/domain/prayer_repository.dart';

/// Sample prayers for local QA — uses real KJV promise IDs from the catalog.
class TestDataImporter {
  TestDataImporter(this._repo, this._prefs);

  final PrayerRepository _repo;
  final SharedPreferences _prefs;

  static const _idsKey = 'test_data_prayer_ids';

  static const samples = <TestSample>[
    TestSample(
      prayer: NewPrayer(
        name: 'Mom’s healing',
        person: 'Mom',
        request:
            'Lord, restore Mom’s strength and give the doctors wisdom. '
            'We ask for healing according to Your will.',
        tags: ['family', 'healing'],
        verseIds: ['jer-33-3', 'mat-7-7-8'],
      ),
    ),
    TestSample(
      prayer: NewPrayer(
        name: 'Job interview',
        person: 'Myself',
        request:
            'Provide the right work and help me trust You with the outcome. '
            'Open doors You have prepared.',
        tags: ['work', 'provision'],
        verseIds: ['mat-7-7-8', '1jo-5-14-15'],
      ),
    ),
    TestSample(
      prayer: NewPrayer(
        name: 'Church unity',
        person: 'Our church',
        request:
            'Knit our congregation together in love and truth. '
            'Guard us from division and fill us with Your Spirit.',
        tags: ['church'],
        verseIds: ['2ch-7-14', 'jhn-14-13-14'],
      ),
    ),
    TestSample(
      prayer: NewPrayer(
        name: 'Anxiety at night',
        person: 'Myself',
        request:
            'Quiet my racing thoughts and teach me to cast every care on You. '
            'Give rest and courage for tomorrow.',
        tags: ['peace', 'personal'],
        verseIds: ['mar-11-24', 'jer-33-3'],
      ),
    ),
    TestSample(
      prayer: NewPrayer(
        name: 'Neighbor’s salvation',
        person: 'Neighbor',
        request:
            'Draw our neighbor to Christ. Soften hearts and give us boldness '
            'to speak Your gospel with gentleness.',
        tags: ['evangelism', 'neighbors'],
        verseIds: ['jon-3-10', '1jo-5-14-15'],
      ),
    ),
    TestSample(
      prayer: NewPrayer(
        name: 'Financial need',
        person: 'Our family',
        request:
            'You know our bills and needs. Provide daily bread and keep us '
            'from worry as we seek Your kingdom first.',
        tags: ['provision', 'family'],
        verseIds: ['mat-7-7-8', '2ch-7-14'],
      ),
      answered: true,
      answeredNote: 'Unexpected overtime covered the shortfall. Praise God.',
    ),
    TestSample(
      prayer: NewPrayer(
        name: 'Safe travel',
        person: 'Our family',
        request:
            'Watch over our trip. Protect us on the road and bring us home '
            'in peace.',
        tags: ['travel', 'family'],
        verseIds: ['1sa-1-27'],
      ),
      answered: true,
      answeredNote: 'Arrived safely. Thank You, Lord.',
    ),
    TestSample(
      prayer: NewPrayer(
        name: 'Wisdom for decision',
        person: 'Our family',
        request:
            'We need clear direction about the move. Speak through Your Word '
            'and give unity in the decision.',
        tags: ['guidance', 'family'],
        verseIds: ['jer-33-3', 'jhn-14-13-14'],
      ),
    ),
  ];

  /// True when any known sample prayers are still in the library.
  Future<bool> isLoaded() async {
    final ids = await findLoadedIds();
    return ids.isNotEmpty;
  }

  /// IDs of sample prayers currently present (prefs first, then content match).
  Future<List<int>> findLoadedIds() async {
    final fromPrefs = await _alivePrefIds();
    if (fromPrefs.isNotEmpty) return fromPrefs;

    final matched = await _matchByContent();
    if (matched.isNotEmpty) {
      await _prefs.setStringList(
        _idsKey,
        matched.map((id) => id.toString()).toList(),
      );
    }
    return matched;
  }

  /// Inserts sample prayers. Returns 0 if already loaded.
  Future<int> importSamples() async {
    if (await isLoaded()) return 0;

    final ids = <int>[];
    for (final sample in samples) {
      final id = await _repo.createPrayer(sample.prayer);
      if (sample.answered) {
        await _repo.setAnswered(
          id,
          answered: true,
          note: sample.answeredNote,
        );
      }
      ids.add(id);
    }
    await _prefs.setStringList(
      _idsKey,
      ids.map((id) => id.toString()).toList(),
    );
    return ids.length;
  }

  /// Deletes all sample prayers. Returns how many were removed.
  Future<int> deleteSamples() async {
    final ids = await findLoadedIds();
    for (final id in ids) {
      await _repo.deletePrayer(id);
    }
    await _prefs.remove(_idsKey);
    return ids.length;
  }

  Future<List<int>> _alivePrefIds() async {
    final raw = _prefs.getStringList(_idsKey) ?? const [];
    final alive = <int>[];
    for (final value in raw) {
      final id = int.tryParse(value);
      if (id == null) continue;
      if (await _repo.getPrayer(id) != null) {
        alive.add(id);
      }
    }
    if (alive.length != raw.length) {
      if (alive.isEmpty) {
        await _prefs.remove(_idsKey);
      } else {
        await _prefs.setStringList(
          _idsKey,
          alive.map((id) => id.toString()).toList(),
        );
      }
    }
    return alive;
  }

  Future<List<int>> _matchByContent() async {
    final all = await _repo.watchPrayers(filter: AnswerFilter.all).first;
    final keys = {
      for (final s in samples) _key(s.prayer.name, s.prayer.request),
    };
    return [
      for (final p in all)
        if (keys.contains(_key(p.name, p.request))) p.id,
    ];
  }

  static String _key(String name, String request) =>
      '${name.trim()}\u0000${request.trim()}';
}

class TestSample {
  const TestSample({
    required this.prayer,
    this.answered = false,
    this.answeredNote,
  });

  final NewPrayer prayer;
  final bool answered;
  final String? answeredNote;
}
