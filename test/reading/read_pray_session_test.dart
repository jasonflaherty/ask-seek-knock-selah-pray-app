import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/reading/application/read_pray_session_notifier.dart';
import 'package:selah/features/reading/domain/read_pray_phase.dart';
import 'package:selah/features/silence/domain/silence_wake_lock.dart';

import '../silence/fake_silence_deps.dart';

class _FakeWakeLock implements SilenceWakeLock {
  bool enabled = false;

  @override
  Future<void> enable() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}

void main() {
  test('read timer hands off to pray timer', () {
    final wake = _FakeWakeLock();
    final bell = FakeSilenceBell();
    final notifier = ReadPraySessionNotifier(wakeLock: wake, bell: bell);

    notifier.startReading();
    expect(notifier.state.phase, ReadPrayPhase.read);
    expect(notifier.state.remainingSeconds, ReadPrayDuration.secondsEach);
    expect(wake.enabled, isTrue);

    notifier.skipToPray();
    expect(notifier.state.phase, ReadPrayPhase.pray);
    expect(notifier.state.remainingSeconds, ReadPrayDuration.secondsEach);
    expect(bell.chimeCount, 0);

    notifier.stop();
    expect(notifier.state.phase, ReadPrayPhase.setup);
    expect(wake.enabled, isFalse);
    expect(bell.chimeCount, 0);
    notifier.dispose();
  });

  test('natural end of read stretch chimes then starts pray', () async {
    final wake = _FakeWakeLock();
    final bell = FakeSilenceBell();
    final notifier = ReadPraySessionNotifier(wakeLock: wake, bell: bell);

    notifier.startReading();
    await notifier.debugForceOneSecondLeftAndTick();

    expect(notifier.state.phase, ReadPrayPhase.pray);
    expect(bell.chimeCount, 1);
    notifier.dispose();
  });

  test('natural end of pray stretch chimes and finishes', () async {
    final wake = _FakeWakeLock();
    final bell = FakeSilenceBell();
    final notifier = ReadPraySessionNotifier(wakeLock: wake, bell: bell);

    notifier.skipToPray();
    await notifier.debugForceOneSecondLeftAndTick();

    expect(notifier.state.phase, ReadPrayPhase.done);
    expect(bell.chimeCount, 1);
    notifier.dispose();
  });

  test('stop does not chime', () {
    final wake = _FakeWakeLock();
    final bell = FakeSilenceBell();
    final notifier = ReadPraySessionNotifier(wakeLock: wake, bell: bell);

    notifier.startReading();
    notifier.stop();
    expect(bell.chimeCount, 0);
    notifier.dispose();
  });
}
