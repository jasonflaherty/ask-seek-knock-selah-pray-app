import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/silence/domain/silence_name_pace.dart';

void main() {
  test('normalize snaps to 5-second steps within bounds', () {
    expect(SilenceNamePace.normalize(5), 5);
    expect(SilenceNamePace.normalize(15), 15);
    expect(SilenceNamePace.normalize(30), 30);
    expect(SilenceNamePace.normalize(7), 5);
    expect(SilenceNamePace.normalize(8), 10);
    expect(SilenceNamePace.normalize(0), 5);
    expect(SilenceNamePace.normalize(100), 30);
  });

  test('faster shortens the slot; slower lengthens it', () {
    expect(SilenceNamePace.decrease(5), 5);
    expect(SilenceNamePace.decrease(10), 5);
    expect(SilenceNamePace.increase(25), 30);
    expect(SilenceNamePace.increase(30), 30);
    expect(SilenceNamePace.canDecrease(5), isFalse);
    expect(SilenceNamePace.canIncrease(30), isFalse);
  });

  test('fade scales with pace and stays within calm bounds', () {
    expect(SilenceNamePace.fadeFor(5), const Duration(milliseconds: 625));
    expect(SilenceNamePace.fadeFor(15), const Duration(milliseconds: 1875));
    expect(SilenceNamePace.fadeFor(30).inMilliseconds, lessThanOrEqualTo(2000));
    expect(SilenceNamePace.fadeFor(5).inMilliseconds, greaterThanOrEqualTo(400));
  });
}
