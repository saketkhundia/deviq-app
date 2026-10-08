import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layout/responsive.dart';

import '../../features/ai_chat/presentation/ai_screen.dart';
import '../../features/analyze/presentation/analyze_screen.dart';
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
GoRouter buildRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/home',
                  pageBuilder: (c, s) => _page(const HomeScreen(), s)),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/analyze',
                  pageBuilder: (c, s) => _page(const AnalyzeScreen(), s)),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/compare',
                  pageBuilder: (c, s) => _page(const CompareScreen(), s)),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/playground',
                  pageBuilder: (c, s) => _page(const PlaygroundScreen(), s)),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/more',
                  pageBuilder: (c, s) => _page(const HomeScreen(), s)),
            ]),
          ],
        ),
        GoRoute(
            path: '/login',
            pageBuilder: (c, s) => _page(const LoginScreen(), s)),
        GoRoute(
            path: '/signup',
            pageBuilder: (c, s) => _page(const SignupScreen(), s)),
        GoRoute(
            path: '/review',
            pageBuilder: (c, s) =>
                _page(const DevIQSubPage(child: ReviewScreen()), s)),
        GoRoute(
            path: '/ai',
            pageBuilder: (c, s) =>
                _page(const DevIQSubPage(child: AiScreen()), s)),
        GoRoute(
            path: '/interview',
            pageBuilder: (c, s) =>
                _page(const DevIQSubPage(child: InterviewScreen()), s)),
        GoRoute(
            path: '/profile',
            pageBuilder: (c, s) =>
                _page(const DevIQSubPage(child: ProfileScreen()), s)),
        GoRoute(
            path: '/history',
            pageBuilder: (c, s) =>
                _page(const DevIQSubPage(child: HistoryScreen()), s)),
        GoRoute(
            path: '/settings',
            pageBuilder: (c, s) =>
                _page(const DevIQSubPage(child: SettingsScreen()), s)),
      ],
    );

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
