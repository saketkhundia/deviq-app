import 'package:deviq/core/routing/app_router.dart';
import 'package:deviq/data/models/auth_models.dart';
import 'package:deviq/data/repositories/auth_repository.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/features/auth/presentation/login_screen.dart';
import 'package:deviq/features/auth/presentation/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthRepo extends Mock implements AuthRepository {}

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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
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
  await t.pumpAndSettle(const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
}

void _authLayoutTests() {
  group('auth layout matrix', () {
    testWidgets('login 360 light', (t) async {
      await _pumpAuth(t, const LoginScreen(), dark: false);
      expect(find.text('Welcome back'), findsOneWidget);
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
      await t.enterText(
          find.byType(TextFormField).at(2), 'StrongPass12!');
      await t.pumpAndSettle();
      expect(find.text('Strong'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}