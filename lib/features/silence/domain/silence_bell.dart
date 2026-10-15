/// Plays the end-of-silence chime. Implementations may be silent in tests.
abstract class SilenceBell {
  Future<void> chime();
  Future<void> dispose();
}
