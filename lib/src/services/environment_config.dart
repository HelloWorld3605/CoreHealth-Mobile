/// Application environment configuration.
/// Injected at build time via --dart-define=ENVIRONMENT=development
class EnvironmentConfig {
  static const _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

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
