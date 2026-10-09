import 'package:selah/features/silence/domain/silence_bell.dart';
import 'package:selah/features/silence/domain/silence_wake_lock.dart';

class FakeSilenceBell implements SilenceBell {
  int chimeCount = 0;

  @override
  Future<void> chime() async {
    chimeCount += 1;
  }

  @override
  Future<void> dispose() async {}
}

class FakeSilenceWakeLock implements SilenceWakeLock {
  bool enabled = false;

  @override
  Future<void> enable() async {
    enabled = true;
  }

  @override
  Future<void> disable() async {
    enabled = false;
  }
}
