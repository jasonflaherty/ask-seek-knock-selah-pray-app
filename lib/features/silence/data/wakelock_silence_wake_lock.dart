import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/silence_wake_lock.dart';

class WakelockSilenceWakeLock implements SilenceWakeLock {
  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}
