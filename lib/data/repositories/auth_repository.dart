import '../../core/networking/api_client.dart';
import '../../core/storage/app_storage.dart';
import '../models/auth_models.dart';

/// Authentication against the existing DevIQ backend. Tokens live in
/// secure storage; the ApiClient is updated on every session change.
class AuthRepository {
  AuthRepository(this._api, this._secure);

  final ApiClient _api;
  final SecureStore _secure;

  Future<({AuthUser user, String token})> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/signup',
      body: {'name': name, 'email': email, 'password': password},
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return _persist(json);
  }

  Future<({AuthUser user, String token})> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      body: {'email': email, 'password': password},
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return _persist(json);
  }

  /// Google sign-in: exchanges a server auth code (obtained natively
  /// on device) for a DevIQ session via the backend's OAuth code
  /// exchange. The verified ID token rides along so the backend can
  /// fall back to direct verification; unknown fields are ignored by
  /// FastAPI validation. Response flows through [_persist].
  Future<({AuthUser user, String token})> oauthGoogle({
    required String email,
    required String code,
    required String redirectUri,
    String? idToken,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/oauth',
      body: {
        'email': email,
        'code': code,
        'redirect_uri': redirectUri,
        if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
      },
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return _persist(json);
  }

  Future<AuthUser> me() async {
    final json = await _api.get<Map<String, dynamic>>(
      '/auth/me',
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    final user = AuthUser.fromJson(
      json['user'] is Map
          ? (json['user'] as Map).cast<String, dynamic>()
          : json,
    );
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post<dynamic>('/auth/logout');
    } catch (_) {
      // Server logout is best-effort; local session always clears.
    }
    await _secure.clearSession();
    _api.setAuth();
  }

  Future<void> deleteAccount() async {
    await _api.delete<dynamic>('/auth/account');
    await _secure.clearSession();
    _api.setAuth();
  }

  /// Restore a persisted session (token + email) into the ApiClient.
  /// Returns false when no session exists.
  Future<bool> restore() async {
    final s = await _secure.readSession();
    if (s == null) return false;
    _api.setAuth(token: s.token, email: s.email);
    return true;
  }

  ({AuthUser user, String token}) _persist(Map<String, dynamic> json) {
    final token =
        (json['token'] ?? json['access_token'] ?? json['session_token'])
            ?.toString() ??
        '';
    final userJson = json['user'] is Map
        ? (json['user'] as Map).cast<String, dynamic>()
        : json;
    // Signup nests the user and carries the id as top-level `uid`.
    userJson.putIfAbsent(
      'id',
      () => json['uid']?.toString() ?? userJson['user_id']?.toString(),
    );
    final user = AuthUser.fromJson(userJson);
    if (token.isEmpty) {
      throw StateError('missing token');
    }
    _secure.saveSession(token: token, email: user.email);
    _api.setAuth(token: token, email: user.email);
    return (user: user, token: token);
  }
}
