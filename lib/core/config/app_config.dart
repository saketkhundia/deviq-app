// Package-visible API configuration.
// Override with: flutter run --dart-define=DEVIQ_API_BASE_URL=http://localhost:8000
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'DEVIQ_API_BASE_URL',
    defaultValue: 'https://deviq-backend-x6a9.onrender.com',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String appName = 'DevIQ';
  static const String tagline = 'Developer Analytics Platform';
}
