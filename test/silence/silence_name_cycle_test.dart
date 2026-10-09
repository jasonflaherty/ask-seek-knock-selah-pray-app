import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/prayers/domain/prayer.dart';
import 'package:selah/features/silence/domain/silence_focus.dart';
import 'package:selah/features/silence/domain/silence_name_cycle.dart';

Prayer _p({
  required String name,
  String person = '',
  bool answered = false,
}) {
  final t = DateTime(2024, 1, 1);
  return Prayer(
    id: name.hashCode,
    name: name,
    person: person,
    request: 'request',
    isAnswered: answered,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('empty names yield null', () {
    expect(
      SilenceNameCycle.nameAt(names: const [], elapsed: Duration.zero),
      isNull,
    );
  });

  test('cycles through names every 15 seconds', () {
    const names = ['Ada', 'Ben', 'Cara'];
    expect(
      SilenceNameCycle.nameAt(names: names, elapsed: Duration.zero),
      'Ada',
    );
    expect(
      SilenceNameCycle.nameAt(names: names, elapsed: const Duration(seconds: 14)),
      'Ada',
    );
    expect(
      SilenceNameCycle.nameAt(names: names, elapsed: const Duration(seconds: 15)),
      'Ben',
    );
    expect(
      SilenceNameCycle.nameAt(names: names, elapsed: const Duration(seconds: 45)),
      'Ada',
    );
  });

  test('focus uses person when set, else name; skips answered', () {
    final names = silenceFocusNames([
      _p(name: 'Title', person: 'Jordan'),
      _p(name: 'Solo'),
      _p(name: 'Done', answered: true),
    ]);
    expect(names, ['Jordan', 'Solo']);
  });
}
