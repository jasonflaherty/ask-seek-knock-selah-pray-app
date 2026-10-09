import 'package:shared_preferences/shared_preferences.dart';

import '../domain/prayer.dart';
import '../domain/prayer_repository.dart';

/// Seeds the journal once on first launch when it is empty.
///
/// These are ordinary prayers. Export and add/edit use the normal journal
/// flows. Clearing the journal later does not bring them back.
class InitialPrayersSeeder {
  InitialPrayersSeeder(this._repo, this._prefs);

  final PrayerRepository _repo;
  final SharedPreferences _prefs;

  static const prefsKey = 'initial_prayers_seeded';

  static const prayers = <NewPrayer>[
    NewPrayer(
      name: 'Eli’s family',
      person: 'Eli',
      request:
          'Reconcile Eli’s family. Give peace and hearts ready to forgive.',
      tags: ['family', 'reconciliation'],
      verseIds: ['jhn-14-27', 'mic-7-18-19'],
    ),
    NewPrayer(
      name: 'Pelle at school',
      person: 'Pelle',
      request:
          'Help Pelle enjoy school and find peace in Your Word.',
      tags: ['school', 'peace'],
      verseIds: ['isa-54-13', 'psa-119-105'],
    ),
    NewPrayer(
      name: 'The Dillons',
      person: 'The Dillons',
      request:
          'Watch over the Dillons in their business and home. '
          'Draw them to salvation in Christ.',
      tags: ['family', 'work', 'salvation'],
      verseIds: ['pro-16-3', 'jhn-14-27', '1ti-2-3-4'],
    ),
    NewPrayer(
      name: 'The Alaries',
      person: 'The Alaries',
      request:
          'Care for the Alaries and their children and jobs. '
          'Draw them to salvation in Christ.',
      tags: ['family', 'children', 'work', 'salvation'],
      verseIds: ['isa-54-13', 'pro-16-3', '2pe-3-9'],
    ),
    NewPrayer(
      name: 'The Smiths',
      person: 'The Smiths',
      request:
          'Grow the Smiths in the Holy Spirit. Raise children who follow '
          'the Lord. Create clean hearts where selfish ways remain.',
      tags: ['family', 'growth', 'children'],
      verseIds: ['phi-1-6', 'isa-54-13', 'psa-51-10'],
    ),
    NewPrayer(
      name: 'Karen, Sage, and Juniper',
      person: 'Karen, Sage, and Juniper',
      request:
          'Grant Karen, Sage, and Juniper salvation, growth, and peace at '
          'home. Help them do well in school. Give us wisdom for parenting.',
      tags: ['family', 'salvation', 'school'],
      verseIds: ['1ti-2-3-4', 'isa-54-13', 'jam-1-5'],
    ),
    NewPrayer(
      name: 'Church elders',
      person: 'Church elders',
      request:
          'Unite our church elders in fellowship. Give wisdom as they work '
          'together through hard decisions.',
      tags: ['church', 'unity'],
      verseIds: ['jam-1-5', 'phi-4-6-7'],
    ),
    NewPrayer(
      name: 'Church bylaws',
      person: 'Church',
      request:
          'Make our bylaws clear and usable, that they serve the church well.',
      tags: ['church', 'wisdom'],
      verseIds: ['jam-1-5', 'psa-32-8'],
    ),
    NewPrayer(
      name: 'Brian and Ashley',
      person: 'Brian and Ashley',
      request:
          'Give Brian and Ashley and their family grace and peace.',
      tags: ['family'],
      verseIds: ['phi-4-6-7', 'heb-4-16'],
    ),
    NewPrayer(
      name: 'Debbie',
      person: 'Debbie',
      request:
          'Watch over Marty’s daughter Debbie. Carry her cares and give peace.',
      tags: ['family'],
      verseIds: ['phi-4-6-7', '1pe-5-7'],
    ),
    NewPrayer(
      name: 'Sarah, Paul, and their boys',
      person: 'Sarah and Paul',
      request:
          'Give Sarah and Paul and their boys grace, peace, and help.',
      tags: ['family', 'children'],
      verseIds: ['isa-54-13', 'phi-4-6-7'],
    ),
    NewPrayer(
      name: 'The Meissners',
      person: 'The Meissners',
      request:
          'Give the Meissners grace and peace.',
      tags: ['family'],
      verseIds: ['phi-4-6-7', 'heb-4-16'],
    ),
    NewPrayer(
      name: 'Bible study',
      person: 'Bible study',
      request:
          'Bless our Bible study and other groups that teach curious '
          'believers. Open hearts to Your Word.',
      tags: ['church', 'teaching'],
      verseIds: ['psa-119-105', '1ti-2-3-4'],
    ),
    NewPrayer(
      name: 'Stillness in prayer',
      person: 'Myself',
      request:
          'Teach me stillness. Help me pray by the Spirit according to '
          'Your will.',
      tags: ['prayer', 'peace'],
      verseIds: ['psa-46-10', 'rom-8-26-27'],
    ),
    NewPrayer(
      name: 'Braden and family',
      person: 'Braden',
      request:
          'Give Braden and his family grace and peace.',
      tags: ['family'],
      verseIds: ['phi-4-6-7', 'heb-4-16'],
    ),
    NewPrayer(
      name: 'Healing',
      person: 'Jody, Mike, Crosby, Tim, and DJ',
      request:
          'Heal Jody, Mike, Crosby, Tim, and DJ according to Your will, '
          'and have mercy.',
      tags: ['healing'],
      verseIds: ['jam-5-14-15', '1jo-5-14-15'],
    ),
  ];

  /// Inserts [prayers] when the journal is empty and the flag is unset.
  /// Returns how many were created.
  Future<int> seedIfNeeded() async {
    if (_prefs.getBool(prefsKey) == true) return 0;

    final existing =
        await _repo.watchPrayers(filter: AnswerFilter.all).first;
    if (existing.isNotEmpty) {
      await _prefs.setBool(prefsKey, true);
      return 0;
    }

    for (final prayer in prayers) {
      await _repo.createPrayer(prayer);
    }
    await _prefs.setBool(prefsKey, true);
    return prayers.length;
  }
}
