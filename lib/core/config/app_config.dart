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

  /// Google OAuth Web client ID used as `serverClientId` when requesting
  /// a server auth code for POST /auth/oauth. This is a public
  /// identifier, not a secret. Override with:
  /// flutter run --dart-define=DEVIQ_GOOGLE_SERVER_CLIENT_ID=...
  ///
  /// Credential map (project `deviq-auth-489209`):
  /// - Web client (BELOW): authorizes the code the backend exchanges.
  /// - Android client: registered with package `online.deviq.deviq`
  ///   + the build's SHA-1. Resolved server-side at runtime.
  static const String googleServerClientId = String.fromEnvironment(
    'DEVIQ_GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '25241869105-2v61rkh4u7ash5ptdnd6c5c1n9nthvu4.apps.googleusercontent.com',
  );

  /// Redirect URI the backend accepts for the OAuth code exchange
  /// (verified against the live allowlist).
  static const String googleOAuthRedirectUri =
      'https://www.deviq.online/auth/callback';

  static const String appName = 'DevIQ';
  static const String tagline = 'Developer Analytics Platform';
}
