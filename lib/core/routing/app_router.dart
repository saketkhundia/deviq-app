import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layout/responsive.dart';

import '../../features/ai_chat/presentation/ai_screen.dart';
import '../../features/analyze/presentation/analyze_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/compare/presentation/compare_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/interview_prep/presentation/interview_screen.dart';
import '../../features/playground/presentation/playground_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'shell.dart';

/// Central routing. Primary tabs use a StatefulShellRoute so each tab
/// keeps its own navigation stack; secondary screens push on top.
///
/// Phase-1 protection: every route except /login and /signup requires an
/// authenticated session. The router re-evaluates on [refresh] signals
/// from the auth state (see main.dart).
GoRouter buildRouter({
  required AuthStatus Function() authStatus,
  required Listenable refresh,
}) => GoRouter(
  initialLocation: '/home',
  refreshListenable: refresh,
  redirect: (context, state) =>
      authRedirect(status: authStatus(), location: state.uri.path),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (c, s) => _page(const HomeScreen(), s),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analyze',
              pageBuilder: (c, s) => _page(const AnalyzeScreen(), s),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/interview',
              pageBuilder: (c, s) => _page(const InterviewScreen(), s),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ai',
              pageBuilder: (c, s) => _page(const AiScreen(), s),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/compare',
      pageBuilder: (c, s) =>
          _page(const DevIQSubPage(child: CompareScreen()), s),
    ),
    GoRoute(
      path: '/playground',
      pageBuilder: (c, s) =>
          _page(const DevIQSubPage(child: PlaygroundScreen()), s),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (c, s) => _page(const LoginScreen(), s),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (c, s) => _page(const SignupScreen(), s),
    ),
    GoRoute(
      path: '/review',
      pageBuilder: (c, s) =>
          _page(const DevIQSubPage(child: ReviewScreen()), s),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (c, s) =>
          _page(const DevIQSubPage(child: ProfileScreen()), s),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (c, s) =>
          _page(const DevIQSubPage(child: HistoryScreen()), s),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (c, s) =>
          _page(const DevIQSubPage(child: SettingsScreen()), s),
    ),
  ],
);

/// Pure route-guard decision (unit tested):
/// - session restoring → no opinion (caller shows splash)
/// - unauthenticated off public pages → /login
/// - authenticated on /login|/signup → /home
/// - otherwise → no redirect.
String? authRedirect({required AuthStatus status, required String location}) {
  const public = ['/login', '/signup'];
  if (status == AuthStatus.unknown) return null;
  final isPublic = public.contains(location);
  if (status != AuthStatus.authenticated && !isPublic) return '/login';
  if (status == AuthStatus.authenticated && isPublic) return '/home';
  return null;
}

CustomTransitionPage<void> _page(Widget child, GoRouterState s) =>
    CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionsBuilder: (context, anim, _, c) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: c,
      ),
      transitionDuration: const Duration(milliseconds: 180),
    );
