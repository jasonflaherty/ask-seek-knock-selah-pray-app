/// Single place for the display name so a rename is a one-line change.
class AppConfig {
  static const String appName = 'Selah';

  /// Venmo profile used by Settings → Support the developer.
  static const String venmoUsername = 'jjflaherty';

  static Uri get venmoSupportUri =>
      Uri.parse('https://venmo.com/u/$venmoUsername');

  /// Group/church sync API (empty disables network sync until dart-define is set).
  static const String selahApiBaseUrl = String.fromEnvironment(
    'SELAH_API_BASE_URL',
    defaultValue: 'https://selah.psithurismlabs.com',
  );

  static bool get selahApiConfigured => selahApiBaseUrl.trim().isNotEmpty;
}
