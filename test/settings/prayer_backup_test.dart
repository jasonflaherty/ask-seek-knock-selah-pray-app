import 'package:flutter_test/flutter_test.dart';
import 'package:selah/core/utils/clock.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/settings/data/prayer_backup.dart';

import '../prayers/fake_prayer_repository.dart';

void main() {
  late FakePrayerRepository repo;
  late PrayerBackupService service;
  final codec = PrayerBackupCodec();

  setUp(() {
    repo = FakePrayerRepository(FakeClock(DateTime(2024, 6, 15)));
    service = PrayerBackupService(repo, codec: codec);
  });

  tearDown(() => repo.dispose());

  test('JSON round-trip preserves person, tags, verses, answered', () async {
    await repo.createPrayer(
      const NewPrayer(
        name: 'Heal Mom',
        person: 'Mom',
        request: 'Please heal',
        tags: ['family'],
        verseIds: ['jer-33-3'],
      ),
    );
    final id = repo.allPrayers.single.id;
    await repo.setAnswered(id, answered: true, note: 'Improving');

    final json = await service.exportJson();
    final decoded = codec.decodeJson(json);
    expect(decoded, hasLength(1));
    expect(decoded.single.person, 'Mom');
    expect(decoded.single.tags, ['family']);
    expect(decoded.single.verseIds, ['jer-33-3']);
    expect(decoded.single.isAnswered, isTrue);
    expect(decoded.single.answeredNote, 'Improving');
  });

  test('CSV round-trip and import creates prayers', () async {
    await repo.createPrayer(
      const NewPrayer(
        name: 'A',
        person: 'Dad',
        request: 'Help',
        tags: ['a', 'b'],
        verseIds: ['v1', 'v2'],
      ),
    );

    final csv = await service.exportCsv();
    expect(csv, contains('name,person,request'));
    expect(csv, contains('Dad'));

    final other = FakePrayerRepository(FakeClock(DateTime(2024, 6, 16)));
    addTearDown(other.dispose);
    final imported =
        await PrayerBackupService(other, codec: codec).importCsv(csv);
    expect(imported, 1);
    expect(other.allPrayers.single.person, 'Dad');
    expect(other.allPrayers.single.tags, ['a', 'b']);
  });

  test('PersonFilter matches person, unassigned, and all', () {
    final now = DateTime(2024, 1, 1);
    final mom = Prayer(
      id: 1,
      name: 'N',
      person: 'Mom',
      request: 'R',
      isAnswered: false,
      createdAt: now,
      updatedAt: now,
    );
    final none = Prayer(
      id: 2,
      name: 'N2',
      request: 'R',
      isAnswered: false,
      createdAt: now,
      updatedAt: now,
    );

    expect(PersonFilter.all.matches(mom), isTrue);
    expect(PersonFilter.all.matches(none), isTrue);
    expect(PersonFilter.named('Mom').matches(mom), isTrue);
    expect(PersonFilter.named('Mom').matches(none), isFalse);
    expect(PersonFilter.unassigned.matches(none), isTrue);
    expect(PersonFilter.unassigned.matches(mom), isFalse);
  });
}
