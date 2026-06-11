/// Application environment configuration.
/// Injected at build time via --dart-define=ENVIRONMENT=development
class EnvironmentConfig {
  static const _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Shared backend base URL (includes the `/api` prefix). Injected via
  /// --dart-define=COREHEALTH_API_BASE_URL=...; defaults to production.
  static const _apiBaseUrl = String.fromEnvironment(
    'COREHEALTH_API_BASE_URL',
    defaultValue: 'https://api.corehealth.page/api',
  );

  /// Backend base URL used by the remote repository and AI services.
  static String get apiBaseUrl => _apiBaseUrl;

  /// Returns true if running in development or local environment.
  static bool get isDevelopment =>
      _environment.toLowerCase() == 'development' ||
      _environment.toLowerCase() == 'local';

  /// Returns true if running in production environment.
  static bool get isProduction =>
      _environment.toLowerCase() == 'production';

  /// Current environment name.
  static String get current => _environment;
}
