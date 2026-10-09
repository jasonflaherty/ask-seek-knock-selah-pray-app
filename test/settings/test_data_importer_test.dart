import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/settings/data/test_data_importer.dart';

import '../prayers/fake_prayer_repository.dart';

void main() {
  late FakePrayerRepository repo;
  late SharedPreferences prefs;
  late TestDataImporter importer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = FakePrayerRepository(FakeClock(DateTime(2024, 6, 15)));
    importer = TestDataImporter(repo, prefs);
  });

  tearDown(() {
    repo.dispose();
  });

  test('import creates samples once and blocks duplicates', () async {
    expect(await importer.isLoaded(), isFalse);

    final first = await importer.importSamples();
    expect(first, TestDataImporter.samples.length);
    expect(await importer.isLoaded(), isTrue);
    expect(repo.allPrayers.length, first);

    final second = await importer.importSamples();
    expect(second, 0);
    expect(repo.allPrayers.length, first);
  });

  test('delete removes only sample prayers', () async {
    await importer.importSamples();
    await repo.createPrayer(
      const NewPrayer(name: 'My real prayer', request: 'Please help'),
    );
    expect(repo.allPrayers.length, TestDataImporter.samples.length + 1);

    final deleted = await importer.deleteSamples();
    expect(deleted, TestDataImporter.samples.length);
    expect(await importer.isLoaded(), isFalse);
    expect(repo.allPrayers.single.name, 'My real prayer');

    final again = await importer.importSamples();
    expect(again, TestDataImporter.samples.length);
  });
}
