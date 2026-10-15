import 'package:flutter_test/flutter_test.dart';
import 'package:selah/features/reading/application/read_pray_session_notifier.dart';
import 'package:selah/features/reading/domain/read_pray_phase.dart';
import 'package:selah/features/silence/domain/silence_wake_lock.dart';

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
    final notifier = ReadPraySessionNotifier(wake);

    notifier.startReading();
    expect(notifier.state.phase, ReadPrayPhase.read);
    expect(notifier.state.remainingSeconds, ReadPrayDuration.secondsEach);
    expect(wake.enabled, isTrue);

    notifier.skipToPray();
    expect(notifier.state.phase, ReadPrayPhase.pray);
    expect(notifier.state.remainingSeconds, ReadPrayDuration.secondsEach);

    notifier.stop();
    expect(notifier.state.phase, ReadPrayPhase.setup);
    expect(wake.enabled, isFalse);
    notifier.dispose();
  });
}
