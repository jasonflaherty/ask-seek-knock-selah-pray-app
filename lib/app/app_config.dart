/// Single place for the display name so a rename is a one-line change.
class AppConfig {
  static const String appName = 'Selah';

  /// Venmo profile used by Settings → Support the developer.
  static const String venmoUsername = 'jjflaherty';

  static Uri get venmoSupportUri =>
      Uri.parse('https://venmo.com/u/$venmoUsername');

  /// Group/church sync API. Pass at build time; empty disables network sync.
  ///
  /// ```bash
  /// flutter run --dart-define=SELAH_API_BASE_URL=https://your-selah-host.example
  /// ```
  static const String selahApiBaseUrl = String.fromEnvironment(
    'SELAH_API_BASE_URL',
    defaultValue: '',
  );

  static bool get selahApiConfigured => selahApiBaseUrl.trim().isNotEmpty;
}
