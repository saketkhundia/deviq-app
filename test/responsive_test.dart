import 'package:deviq/data/models/auth_models.dart';
import 'package:deviq/data/repositories/misc_repositories.dart';
import 'package:deviq/features/ai_chat/presentation/ai_screen.dart';
import 'package:deviq/features/analyze/presentation/analyze_screen.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/auth/presentation/login_screen.dart';
import 'package:deviq/features/auth/presentation/signup_screen.dart';
import 'package:deviq/features/compare/presentation/compare_screen.dart';
import 'package:deviq/features/history/presentation/history_screen.dart';
import 'package:deviq/features/home/presentation/home_screen.dart';
import 'package:deviq/features/interview_prep/presentation/interview_screen.dart';
import 'package:deviq/features/playground/presentation/playground_screen.dart';
import 'package:deviq/features/profile/presentation/profile_screen.dart';
import 'package:deviq/features/review/presentation/review_screen.dart';
import 'package:deviq/features/settings/presentation/settings_screen.dart';
import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/shared/layout/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeInterviewRepo extends Mock implements InterviewRepository {}

class _FakeProfileRepo extends Mock implements ProfileRepository {}

/// Pumps [screen] at an exact phone viewport and fails on ANY layout
/// exception (RenderFlex/RenderBox overflow, unbounded constraints,
/// missing Material).
/// This is the automated guard for the NO-OVERFLOW quality bar.
///
/// [pushed] mirrors go_router exactly: screens above the tab shell render
/// inside [DevIQSubPage] (their real host) instead of a test Scaffold —
/// this is what catches "No Material widget found" regressions.
Future<void> expectFits(
  WidgetTester t,
  Widget screen, {
  double width = 360,
  double height = 800,
  bool dark = true,
  double textScale = 1.0,
  bool pushed = false,
  List<Override> overrides = const [],
}) async {
  t.view.physicalSize = Size(width * 3, height * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
  await t.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: DevIQTheme.light(),
        darkTheme: DevIQTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: pushed
            ? DevIQSubPage(child: screen)
            : Scaffold(
                body: SafeArea(
                  child: Builder(
                    builder: (context) => MediaQuery(
                      // Preserve ambient size/padding; adjust text scale only.
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(textScale),
                      ),
                      child: screen,
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
  await t.pumpAndSettle(const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  expect(t.takeException(), isNull,
      reason: 'Layout overflow/exception at ${width}x$height '
          '${dark ? 'dark' : 'light'} (scale $textScale)');
}

void main() {
  group('mobile layout fits 360x800 dark (primary target)', () {
    testWidgets('home', (t) => expectFits(t, const HomeScreen()));
    testWidgets('analyze idle', (t) => expectFits(t, const AnalyzeScreen()));
    testWidgets('compare idle', (t) => expectFits(t, const CompareScreen()));
    testWidgets('review idle',
        (t) => expectFits(t, const ReviewScreen(), pushed: true));
    testWidgets('history empty',
        (t) => expectFits(t, const HistoryScreen(), pushed: true));
    testWidgets('settings',
        (t) => expectFits(t, const SettingsScreen(), pushed: true));
    testWidgets(
        'playground', (t) => expectFits(t, const PlaygroundScreen()));
    testWidgets(
        'ai chat', (t) => expectFits(t, const AiScreen(), pushed: true));
    testWidgets('login', (t) => expectFits(t, const LoginScreen()));
    testWidgets('signup', (t) => expectFits(t, const SignupScreen()));
  });

  group('profile + interview (stubbed repos, no network)', () {
    late _FakeProfileRepo profiles;
    late _FakeInterviewRepo interviews;

    setUp(() {
      profiles = _FakeProfileRepo();
      when(() => profiles.fetch())
          .thenAnswer((_) async => UserProfile.empty());
      when(() => profiles.connectedAccounts())
          .thenAnswer((_) async => <String, bool>{});
      interviews = _FakeInterviewRepo();
      when(() => interviews.companyProblems(any()))
          .thenAnswer((_) async => []);
    });

    testWidgets('profile', (t) => expectFits(
          t,
          const ProfileScreen(),
          pushed: true,
          overrides: [profileRepoProvider.overrideWithValue(profiles)],
        ));
    testWidgets('interview empty problems', (t) => expectFits(
          t,
          const InterviewScreen(),
          pushed: true,
          overrides: [interviewRepoProvider.overrideWithValue(interviews)],
        ));
  });

  group('viewport matrix', () {
    testWidgets('home 360 light', (t) async {
      await expectFits(t, const HomeScreen(), dark: false);
    });
    testWidgets('analyze 375 dark', (t) async {
      await expectFits(t, const AnalyzeScreen(), width: 375, height: 812);
    });
    testWidgets('home 390 dark', (t) async {
      await expectFits(t, const HomeScreen(), width: 390, height: 844);
    });
    testWidgets('compare 412 dark', (t) async {
      await expectFits(t, const CompareScreen(), width: 412, height: 915);
    });
    testWidgets('home 430 dark', (t) async {
      await expectFits(t, const HomeScreen(), width: 430, height: 932);
    });
    testWidgets('analyze large text', (t) async {
      await expectFits(t, const AnalyzeScreen(), textScale: 1.25);
    });
    testWidgets('settings small 320', (t) async {
      await expectFits(t, const SettingsScreen(),
          width: 320, height: 700, pushed: true);
    });
    testWidgets('ai chat 360 light pushed', (t) async {
      await expectFits(t, const AiScreen(), dark: false, pushed: true);
    });
  });
}
