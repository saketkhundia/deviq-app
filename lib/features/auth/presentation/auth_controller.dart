import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../app/providers/app_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.working = false,
  });
  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  final bool working;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool? working,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    error: error,
    working: working ?? this.working,
  );
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
    : super(const AuthState(status: AuthStatus.unknown));

  final Ref _ref;

  /// Submission guard for duplicate-tap protection in screens.
  bool get working => state.working;

  Future<void> bootstrap() async {
    final repo = _ref.read(authRepoProvider);
    final has = await repo.restore();
    if (!has) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // Token persisted but invalid — drop to signed-out without wiping
      // unrelated prefs. Session restore failure is not fatal.
      await repo.logout();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(working: true, error: null);
    try {
      final r = await _ref
          .read(authRepoProvider)
          .login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: r.user);
      return true;
    } catch (e) {
      state = state.copyWith(working: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(working: true, error: null);
    try {
      final r = await _ref
          .read(authRepoProvider)
          .signup(name: name, email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: r.user);
      return true;
    } catch (e) {
      state = state.copyWith(working: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authRepoProvider).logout();
    await _signOutGoogle();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    await _ref.read(authRepoProvider).deleteAccount();
    await _signOutGoogle(disconnect: true);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Best-effort Google sign-out so a device account picker appears
  /// again next time. Never fails logout/delete.
  Future<void> _signOutGoogle({bool disconnect = false}) async {
    try {
      final g = GoogleSignIn(
        serverClientId: AppConfig.googleServerClientId,
      );
      if (disconnect) {
        await g.disconnect();
      } else {
        await g.signOut();
      }
    } catch (_) {
      // Native account state is advisory only.
    }
  }

  GoogleSignIn _googleClient() => GoogleSignIn(
    serverClientId: AppConfig.googleServerClientId,
    // Explicit: account.email is required for POST /auth/oauth.
    scopes: const ['email'],
    // Android: always mint a fresh server auth code for the backend
    // exchange instead of reusing a cached grant.
    forceCodeForRefreshToken: true,
  );

  /// Native Google sign-in: account picker → server auth code →
  /// backend OAuth exchange → session. Returns false (no error) when
  /// the user dismisses the picker.
  Future<bool> signInWithGoogle() =>
      googleFlow(() => _googleClient().signIn());

  /// Testable core of [signInWithGoogle] with the native account
  /// picker injected, so unit tests never touch platform channels.
  @visibleForTesting
  Future<bool> googleFlow(
    Future<GoogleSignInAccount?> Function() start,
  ) async {
    state = state.copyWith(working: true, error: null);
    try {
      final account = await start();
      if (account == null) {
        state = state.copyWith(working: false);
        return false;
      }
      final email = account.email;
      final code = account.serverAuthCode;
      if (email.isEmpty || code == null || code.isEmpty) {
        state = state.copyWith(
          working: false,
          error: 'Google sign-in did not return an authorization code.',
        );
        return false;
      }
      // The ID token travels alongside so the backend can verify
      // identity directly if the code exchange ever cannot complete.
      String? idToken;
      try {
        idToken = (await account.authentication).idToken;
      } catch (_) {
        idToken = null;
      }
      final r = await _ref
          .read(authRepoProvider)
          .oauthGoogle(
            email: email,
            code: code,
            redirectUri: AppConfig.googleOAuthRedirectUri,
            idToken: idToken,
          );
      state = AuthState(status: AuthStatus.authenticated, user: r.user);
      return true;
    } catch (e) {
      debugPrint(
        'Google sign-in failed: ${sanitizeOAuthDetails(e.toString())}',
      );
      state = state.copyWith(working: false, error: _googleError(e));
      return false;
    }
  }

  /// Human-readable Google failure. Raw platform exceptions (keystore
  /// details, API codes) stay in debug logs — never in the UI.
  @visibleForTesting
  static String googleError(Object e) => _googleError(e);

  static String _googleError(Object e) {
    if (e is PlatformException) {
      final details = '${e.code} ${e.message ?? ''}';
      // GMS ApiException: 10 (DEVELOPER_ERROR) = this exact app build
      // (package + SHA-1) is not registered under an Android OAuth
      // client in the same Cloud project as the Web client ID.
      if (e.code == 'sign_in_failed' && details.contains('ApiException: 10')) {
        return 'Google sign-in is not set up for this app build (error 10). '
            'Add this build\u2019s SHA-1 fingerprint for package '
            'online.deviq.deviq in Google Cloud Console, then retry.';
      }
      // Google's own embedded login page rejecting the request (the
      // "400 malformed" dialog): same registration problem, or no
      // Google account on the device to complete the flow.
      if (e.code == 'sign_in_failed' &&
          (details.contains('400') || details.contains('malformed'))) {
        return 'Google rejected the sign-in request. Add a Google '
            'account on the device (Settings → Accounts), confirm the '
            'app\u2019s SHA-1 is registered, then retry.';
      }
      if (e.code == 'network_error') {
        return 'No network connection. Check connectivity and retry.';
      }
    }
    // ApiException messages are server-authored for UI display (e.g.
    // "Google token exchange failed") — surface them verbatim instead
    // of hiding the real cause behind generic copy.
    if (e is ApiException) return e.message;
    return 'Google sign-in failed. Please try again.';
  }

  /// Safe OAuth diagnostics for logs: keeps client_id, redirect target
  /// and error codes; strips every secret-bearing value (tokens,
  /// codes, secrets, passwords). Never shown in UI.
  @visibleForTesting
  static String sanitizeOAuthDetails(String raw) {
    var out = raw;
    for (final key in [
      'id_token',
      'idToken',
      'access_token',
      'accessToken',
      'refresh_token',
      'serverAuthCode',
      'server_auth_code',
      'authCode',
      'code',
      'client_secret',
      'password',
    ]) {
      out = out.replaceAllMapped(
        RegExp(
          '(^|[\\s?&"\'])($key)(["\']?\\s*[:=]\\s*["\']?)([^"\'\\s,}]+)',
          caseSensitive: false,
        ),
        (m) => '${m.group(1)}${m.group(2)}${m.group(3)}***',
      );
    }
    // Redirect URIs: keep scheme + host + path, drop query/fragment.
    out = out.replaceAllMapped(
      RegExp(r'(redirect_uri=)([^\s&]+)', caseSensitive: false),
      (m) {
        final uri = Uri.tryParse(m.group(2) ?? '');
        final safe = uri == null
            ? '***'
            : '${uri.scheme}://${uri.host}${uri.path}';
        return '${m.group(1)}$safe';
      },
    );
    return out;
  }
}
