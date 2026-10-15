import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/silence/domain/silence_duration.dart';

void main() {
  test('normalize snaps to 5-minute steps within bounds', () {
    expect(SilenceDuration.normalize(5), 5);
    expect(SilenceDuration.normalize(15), 15);
    expect(SilenceDuration.normalize(60), 60);
    expect(SilenceDuration.normalize(7), 5);
    expect(SilenceDuration.normalize(8), 10);
    expect(SilenceDuration.normalize(0), 5);
    expect(SilenceDuration.normalize(100), 60);
  });

  test('decrease and increase step by 5 and stop at bounds', () {
    expect(SilenceDuration.decrease(5), 5);
    expect(SilenceDuration.decrease(10), 5);
    expect(SilenceDuration.increase(55), 60);
    expect(SilenceDuration.increase(60), 60);
    expect(SilenceDuration.canDecrease(5), isFalse);
    expect(SilenceDuration.canDecrease(10), isTrue);
    expect(SilenceDuration.canIncrease(60), isFalse);
    expect(SilenceDuration.canIncrease(55), isTrue);
  });
}
