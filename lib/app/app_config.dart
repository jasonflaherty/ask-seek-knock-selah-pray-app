/// Single place for the display name so a rename is a one-line change.
class AppConfig {
  static const String appName = 'Selah';

  /// Venmo profile used by Settings → Support the developer.
  static const String venmoUsername = 'jjflaherty';

  static Uri get venmoSupportUri =>
      Uri.parse('https://venmo.com/u/$venmoUsername');
}
