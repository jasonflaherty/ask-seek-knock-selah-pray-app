/// Keeps the screen awake while a silence session is running.
abstract class SilenceWakeLock {
  Future<void> enable();
  Future<void> disable();
}
