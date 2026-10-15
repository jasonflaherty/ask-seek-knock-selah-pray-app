import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/data/initial_prayers.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/settings/data/prayer_backup.dart';

import 'fake_prayer_repository.dart';

void main() {
  late FakePrayerRepository repo;
  late SharedPreferences prefs;
  late InitialPrayersSeeder seeder;
  final codec = PrayerBackupCodec();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = FakePrayerRepository(FakeClock(DateTime(2024, 6, 15)));
    seeder = InitialPrayersSeeder(repo, prefs);
  });

  tearDown(() {
    repo.dispose();
  });

  test('seeds sixteen prayers once on an empty journal', () async {
    final first = await seeder.seedIfNeeded();
    expect(first, InitialPrayersSeeder.prayers.length);
    expect(repo.allPrayers, hasLength(InitialPrayersSeeder.prayers.length));
    expect(prefs.getBool(InitialPrayersSeeder.prefsKey), isTrue);

    final second = await seeder.seedIfNeeded();
    expect(second, 0);
    expect(repo.allPrayers, hasLength(InitialPrayersSeeder.prayers.length));
  });

  test('leaves an existing journal alone and sets the flag', () async {
    await repo.createPrayer(
      const NewPrayer(name: 'Already here', request: 'Please help'),
    );

    final count = await seeder.seedIfNeeded();
    expect(count, 0);
    expect(repo.allPrayers, hasLength(1));
    expect(repo.allPrayers.single.name, 'Already here');
    expect(prefs.getBool(InitialPrayersSeeder.prefsKey), isTrue);

    final again = await seeder.seedIfNeeded();
    expect(again, 0);
    expect(repo.allPrayers, hasLength(1));
  });

  test('seeded prayers survive JSON and CSV export', () async {
    await seeder.seedIfNeeded();
    final service = PrayerBackupService(repo, codec: codec);

    final json = await service.exportJson();
    final fromJson = codec.decodeJson(json);
    expect(fromJson, hasLength(InitialPrayersSeeder.prayers.length));

    final csv = await service.exportCsv();
    final fromCsv = codec.decodeCsv(csv);
    expect(fromCsv, hasLength(InitialPrayersSeeder.prayers.length));

    for (final expected in InitialPrayersSeeder.prayers) {
      final j = fromJson.singleWhere((r) => r.name == expected.name);
      expect(j.person, expected.person);
      expect(j.request, expected.request);
      expect(j.tags, expected.tags);
      expect(j.verseIds, expected.verseIds);

      final c = fromCsv.singleWhere((r) => r.name == expected.name);
      expect(c.person, expected.person);
      expect(c.request, expected.request);
      expect(c.tags, expected.tags);
      expect(c.verseIds, expected.verseIds);
    }
  });
}
