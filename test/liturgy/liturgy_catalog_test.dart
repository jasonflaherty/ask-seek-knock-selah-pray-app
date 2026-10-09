import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/liturgy/data/liturgy_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final prayers = LiturgyCatalog.parse(
    File('assets/liturgy/collects.json').readAsStringSync(),
  );

  test('loads morning and evening fixed collects', () {
    expect(prayers, isNotEmpty);

    final morningPeace = prayers.firstWhere((p) => p.id == 'morning-peace');
    expect(morningPeace.section, 'Morning');
    expect(morningPeace.title, 'Collect for Peace');

    final eveningPerils = prayers.firstWhere((p) => p.id == 'evening-perils');
    expect(eveningPerils.section, 'Evening');
    expect(eveningPerils.text, contains('Lighten our darkness'));

    final common = prayers.firstWhere((p) => p.id == 'common-supplications');
    expect(common.section, 'After the Collects');
    expect(common.title, isNot(contains('Chrysostom')));
  });

  test('excludes saint, Marian, and angel feasts', () {
    final blockedTitle = RegExp(
      r'\b(saint|st\.|mary|annunciation|purification|michael|angel|all saints)\b',
      caseSensitive: false,
    );
    final blockedBodyAddress = RegExp(
      r'\b(blessed virgin mary|holy mary|saint mary|our lady)\b',
      caseSensitive: false,
    );

    for (final prayer in prayers) {
      expect(
        blockedTitle.hasMatch(prayer.title),
        isFalse,
        reason: 'blocked title: ${prayer.title}',
      );
      expect(
        blockedBodyAddress.hasMatch(prayer.text),
        isFalse,
        reason: 'blocked address in ${prayer.id}',
      );
    }
  });

  test('includes christian year landmarks', () {
    final titles = prayers.map((p) => p.title).toSet();
    expect(titles, contains('The First Sunday in Advent'));
    expect(titles, contains('Ash Wednesday'));
    expect(titles, contains('Good Friday: for the Church'));
    expect(titles, contains('Easter Day'));
    expect(titles, contains('Whitsunday'));
    expect(titles, contains('Trinity Sunday'));
    expect(titles, contains('The Twenty-Fifth Sunday after Trinity'));
  });
}
