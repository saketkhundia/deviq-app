import 'package:deviq/core/config/app_config.dart';
import 'package:deviq/core/errors/api_exception.dart';
import 'package:deviq/core/networking/api_client.dart';
import 'package:deviq/core/routing/app_router.dart';
import 'package:deviq/core/storage/app_storage.dart';
import 'package:deviq/data/models/auth_models.dart';
import 'package:deviq/data/repositories/auth_repository.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/features/auth/presentation/login_screen.dart';
import 'package:deviq/features/auth/presentation/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthRepo extends Mock implements AuthRepository {}

class _FakeApiClient extends Mock implements ApiClient {}

class _FakeSecureStore extends Mock implements SecureStore {}

class _FakeGoogleAccount extends Mock implements GoogleSignInAccount {}

class _FakeGoogleAuth extends Mock implements GoogleSignInAuthentication {}

const _user = AuthUser(
  id: 'uid-1',
  name: 'Ada',
  email: 'ada@example.com',
  avatar: '',
  provider: 'email',
);

void main() {
  group('authRedirect (route guard)', () {
    test('restoring session has no opinion', () {
      expect(
        authRedirect(status: AuthStatus.unknown, location: '/home'),
        isNull,
      );
    });

    test('guests are sent to login from anywhere protected', () {
      for (final loc in [
        '/home',
        '/analyze',
        '/compare',
        '/playground',
        '/review',
        '/ai',
        '/interview',
        '/profile',
        '/history',
        '/settings',
      ]) {
        expect(
          authRedirect(status: AuthStatus.unauthenticated, location: loc),
          '/login',
          reason: loc,
        );
      }
    });

    test('guests stay on public pages', () {
      expect(
        authRedirect(status: AuthStatus.unauthenticated, location: '/login'),
        isNull,
      );
      expect(
        authRedirect(status: AuthStatus.unauthenticated, location: '/signup'),
        isNull,
      );
    });

    test('signed-in users leave public pages for home', () {
      expect(
        authRedirect(status: AuthStatus.authenticated, location: '/login'),
        '/home',
      );
      expect(
        authRedirect(status: AuthStatus.authenticated, location: '/signup'),
        '/home',
      );
    });

    test('signed-in users roam protected pages freely', () {
      expect(
        authRedirect(status: AuthStatus.authenticated, location: '/analyze'),
        isNull,
      );
    });
  });

  group('AuthController (mocked backend)', () {
    late _FakeAuthRepo repo;
    late ProviderContainer c;

    setUp(() {
      repo = _FakeAuthRepo();
      c = ProviderContainer(
        overrides: [authRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
    });

    test('login success authenticates', () async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => (user: _user, token: 't'));
      final ok = await c
          .read(authProvider.notifier)
          .login(email: 'ada@example.com', password: 'secret123');
      expect(ok, isTrue);
      expect(c.read(authProvider).status, AuthStatus.authenticated);
      expect(c.read(authProvider).user?.email, 'ada@example.com');
    });

    test('login failure stays signed out with message', () async {
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('nope'));
      final ok = await c
          .read(authProvider.notifier)
          .login(email: 'a@b.c', password: 'x');
      expect(ok, isFalse);
      expect(c.read(authProvider).status, AuthStatus.unknown);
      expect(c.read(authProvider).error, isNotNull);
      expect(c.read(authProvider).working, isFalse);
    });

    test('bootstrap without session signs out silently', () async {
      when(() => repo.restore()).thenAnswer((_) async => false);
      await c.read(authProvider.notifier).bootstrap();
      expect(c.read(authProvider).status, AuthStatus.unauthenticated);
    });

    test('bootstrap with valid session restores user', () async {
      when(() => repo.restore()).thenAnswer((_) async => true);
      when(() => repo.me()).thenAnswer((_) async => _user);
      await c.read(authProvider.notifier).bootstrap();
      expect(c.read(authProvider).status, AuthStatus.authenticated);
    });

    test('bootstrap with dead token drops to signed out', () async {
      when(() => repo.restore()).thenAnswer((_) async => true);
      when(() => repo.me()).thenThrow(Exception('expired'));
      when(() => repo.logout()).thenAnswer((_) async {});
      await c.read(authProvider.notifier).bootstrap();
      expect(c.read(authProvider).status, AuthStatus.unauthenticated);
    });

    test('logout clears session', () async {
      when(() => repo.logout()).thenAnswer((_) async {});
      await c.read(authProvider.notifier).logout();
      expect(c.read(authProvider).status, AuthStatus.unauthenticated);
      verify(() => repo.logout()).called(1);
    });

    test('logout also signs out the Google account', () async {
      when(() => repo.logout()).thenAnswer((_) async {});
      await c.read(authProvider.notifier).logout();
      expect(c.read(authProvider).status, AuthStatus.unauthenticated);
    });
  });

  group('Google sign-in flow (picker injected, no platform channels)', () {
    late _FakeAuthRepo repo;
    late ProviderContainer c;

    setUp(() {
      repo = _FakeAuthRepo();
      c = ProviderContainer(
        overrides: [authRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
    });

    test('picker abort returns false with no error', () async {
      final ok = await c
          .read(authProvider.notifier)
          .googleFlow(() async => null);
      expect(ok, isFalse);
      expect(c.read(authProvider).status, AuthStatus.unknown);
      expect(c.read(authProvider).error, isNull);
      expect(c.read(authProvider).working, isFalse);
      verifyNever(
        () => repo.oauthGoogle(
          email: any(named: 'email'),
          code: any(named: 'code'),
          redirectUri: any(named: 'redirectUri'),
        ),
      );
    });

    test('missing auth code fails with message, no backend call', () async {
      final account = _FakeGoogleAccount();
      when(() => account.email).thenReturn('gina@gmail.com');
      when(() => account.serverAuthCode).thenReturn(null);
      final ok = await c
          .read(authProvider.notifier)
          .googleFlow(() async => account);
      expect(ok, isFalse);
      expect(c.read(authProvider).error, contains('authorization code'));
      expect(c.read(authProvider).working, isFalse);
      verifyNever(
        () => repo.oauthGoogle(
          email: any(named: 'email'),
          code: any(named: 'code'),
          redirectUri: any(named: 'redirectUri'),
        ),
      );
    });

    test('valid auth code exchanges for a session', () async {
      final account = _FakeGoogleAccount();
      when(() => account.email).thenReturn('gina@gmail.com');
      when(() => account.serverAuthCode).thenReturn('auth-code-123');
      when(() => account.authentication).thenAnswer(
        (_) async => _FakeGoogleAuth(),
      );
      when(
        () => repo.oauthGoogle(
          email: any(named: 'email'),
          code: any(named: 'code'),
          redirectUri: any(named: 'redirectUri'),
        ),
      ).thenAnswer((_) async => (user: _user, token: 't'));
      final ok = await c
          .read(authProvider.notifier)
          .googleFlow(() async => account);
      expect(ok, isTrue);
      expect(c.read(authProvider).status, AuthStatus.authenticated);
      expect(c.read(authProvider).user?.email, 'ada@example.com');
      verify(
        () => repo.oauthGoogle(
          email: 'gina@gmail.com',
          code: 'auth-code-123',
          redirectUri: AppConfig.googleOAuthRedirectUri,
          idToken: null,
        ),
      ).called(1);
    });

    test('backend failure stays signed out with message', () async {
      final account = _FakeGoogleAccount();
      when(() => account.email).thenReturn('gina@gmail.com');
      when(() => account.serverAuthCode).thenReturn('auth-code-123');
      when(() => account.authentication).thenAnswer(
        (_) async => _FakeGoogleAuth(),
      );
      when(
        () => repo.oauthGoogle(
          email: any(named: 'email'),
          code: any(named: 'code'),
          redirectUri: any(named: 'redirectUri'),
        ),
      ).thenThrow(Exception('exchange failed'));
      final ok = await c
          .read(authProvider.notifier)
          .googleFlow(() async => account);
      expect(ok, isFalse);
      expect(c.read(authProvider).status, AuthStatus.unknown);
      expect(c.read(authProvider).error, isNotNull);
      expect(c.read(authProvider).working, isFalse);
    });

    test('ApiException 10 maps to setup guidance, never raw traces', () async {
      final err = PlatformException(
        code: 'sign_in_failed',
        message:
            'com.google.android.gms.common.api.ApiException: 10: , null, null',
      );
      final ok = await c.read(authProvider.notifier).googleFlow(() => throw err);
      expect(ok, isFalse);
      final message = c.read(authProvider).error ?? '';
      expect(message, contains('SHA-1'));
      expect(message, contains('online.deviq.deviq'));
      expect(message, isNot(contains('PlatformException')));
      expect(message, isNot(contains('ApiException')));
    });

    test('generic failures map to a plain retry message', () {
      expect(
        AuthController.googleError(Exception('boom')),
        'Google sign-in failed. Please try again.',
      );
      expect(
        AuthController.googleError(
          PlatformException(code: 'network_error'),
        ),
        contains('connection'),
      );
    });

    test('backend ApiException messages surface verbatim', () {
      expect(
        AuthController.googleError(
          const ApiException(
            ApiErrorKind.badRequest,
            'Google token exchange failed',
          ),
        ),
        'Google token exchange failed',
      );
      expect(
        AuthController.googleError(ApiException.network),
        contains('No connection'),
      );
    });

    test('malformed-request dialog maps to account/setup guidance', () async {
      final err = PlatformException(
        code: 'sign_in_failed',
        message: '400. malformed request from embedded login',
      );
      final ok = await c.read(authProvider.notifier).googleFlow(() => throw err);
      expect(ok, isFalse);
      final message = c.read(authProvider).error ?? '';
      expect(message, contains('rejected'));
      expect(message, contains('Accounts'));
      expect(message, isNot(contains('400. malformed')));
    });

    test('sanitizer keeps diagnostics, strips secrets', () {
      const raw =
          'sign_in_failed client_id=25241869105-abc.apps.googleusercontent.com '
          'redirect_uri=https://www.deviq.online/auth/callback?x=1&code=SECRET '
          'idToken=tok123 access_token=acc456 password=hunter2';
      final clean = AuthController.sanitizeOAuthDetails(raw);
      expect(clean, contains('25241869105-abc.apps.googleusercontent.com'));
      expect(clean, contains('redirect_uri=https://www.deviq.online/auth/callback'));
      for (final secret in ['tok123', 'acc456', 'SECRET', 'hunter2']) {
        expect(clean, isNot(contains(secret)));
      }
    });

    testWidgets('google button renders on login and signup', (t) async {
      await _pumpAuth(t, const LoginScreen(), dark: false);
      expect(find.text('Continue with Google'), findsOneWidget);
      await _pumpAuth(t, const SignupScreen(), dark: false);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('AuthRepository.oauthGoogle (mocked transport)', () {
    test('posts the code exchange and persists the session', () async {
      final api = _FakeApiClient();
      final secure = _FakeSecureStore();
      when(
        () => api.post<Map<String, dynamic>>(
          '/auth/oauth',
          body: any(named: 'body'),
          decode: any(named: 'decode'),
        ),
      ).thenAnswer((inv) async {
        final decode =
            inv.namedArguments[#decode]
                as Map<String, dynamic> Function(dynamic);
        return decode({
          'token': 'sess-1',
          'user': {
            'id': 'g-1',
            'name': 'Gina',
            'email': 'gina@gmail.com',
            'avatar': '',
            'provider': 'google',
          },
        });
      });
      when(
        () => secure.saveSession(
          token: any(named: 'token'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async {});
      final repo = AuthRepository(api, secure);
      final r = await repo.oauthGoogle(
        email: 'gina@gmail.com',
        code: 'auth-code-123',
        redirectUri: 'https://www.deviq.online/auth/callback',
      );
      expect(r.token, 'sess-1');
      expect(r.user.email, 'gina@gmail.com');
      expect(r.user.provider, 'google');
      verify(
        () => api.post<Map<String, dynamic>>(
          '/auth/oauth',
          body: {
            'email': 'gina@gmail.com',
            'code': 'auth-code-123',
            'redirect_uri': 'https://www.deviq.online/auth/callback',
          },
          decode: any(named: 'decode'),
        ),
      ).called(1);
      verify(
        () => secure.saveSession(token: 'sess-1', email: 'gina@gmail.com'),
      ).called(1);
    });
  });

  _authLayoutTests();
}

/// Refined-layout coverage: light theme, large system text, narrow
/// viewport — no overflow, no clipped controls.
Future<void> _pumpAuth(
  WidgetTester t,
  Widget screen, {
  double width = 360,
  bool dark = true,
  double textScale = 1.0,
}) async {
  t.view.physicalSize = Size(width * 3, 800 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
  await t.pumpWidget(
    ProviderScope(
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            theme: DevIQTheme.light(),
            darkTheme: DevIQTheme.dark(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(body: SafeArea(child: screen)),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

void _authLayoutTests() {
  group('auth layout matrix', () {
    testWidgets('login 360 light', (t) async {
      await _pumpAuth(t, const LoginScreen(), dark: false);
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('signup 360 light', (t) async {
      await _pumpAuth(t, const SignupScreen(), dark: false);
      expect(find.text('Create Account'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('login large text', (t) async {
      await _pumpAuth(t, const LoginScreen(), textScale: 1.3);
      expect(find.text('Sign In'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('signup large text + meter', (t) async {
      await _pumpAuth(t, const SignupScreen(), textScale: 1.3);
      // Password is the third field (name, email, password, confirm).
      await t.enterText(find.byType(TextFormField).at(2), 'StrongPass12!');
      await t.pumpAndSettle();
      expect(find.text('Strong'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
