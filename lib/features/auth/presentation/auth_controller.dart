import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth_models.dart';
import '../../app/providers/app_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState(
      {required this.status, this.user, this.error, this.working = false});
  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  final bool working;

  AuthState copyWith(
          {AuthStatus? status,
          AuthUser? user,
          String? error,
          bool? working}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        working: working ?? this.working,
      );
}

final authProvider =
    StateNotifierProvider<AuthController, AuthState>(
        (ref) => AuthController(ref));

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
      : super(const AuthState(status: AuthStatus.unknown));

  final Ref _ref;

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

  Future<bool> signup(
      {required String name,
      required String email,
      required String password}) async {
    state = state.copyWith(working: true, error: null);
    try {
      final r = await _ref.read(authRepoProvider).signup(
          name: name, email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: r.user);
      return true;
    } catch (e) {
      state = state.copyWith(working: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authRepoProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    await _ref.read(authRepoProvider).deleteAccount();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
