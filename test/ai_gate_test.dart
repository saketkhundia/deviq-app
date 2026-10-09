import 'package:deviq/core/errors/api_exception.dart';
import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/data/models/analysis_models.dart';
import 'package:deviq/data/models/auth_models.dart';
import 'package:deviq/data/models/github_models.dart';
import 'package:deviq/data/repositories/ai_repository.dart';
import 'package:deviq/data/repositories/auth_repository.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/ai_chat/presentation/ai_screen.dart';
import 'package:deviq/features/analyze/presentation/widgets/ai_insights_panel.dart';
import 'package:deviq/features/auth/presentation/auth_controller.dart';
import 'package:deviq/features/review/presentation/review_screen.dart';
import 'package:deviq/shared/widgets/deviq_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// AI endpoints 401 without a session token — these tests pin the
/// sign-in gates that replace the raw backend error.
Future<void> _pumpGated(WidgetTester t, Widget screen) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
  await t.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        darkTheme: DevIQTheme.dark(),
        themeMode: ThemeMode.dark,
        // No auth session → gates must show; no Scaffold on purpose
        // would crash inputs, so the gate itself proves Material safety
        // only where the screen provides it (review/ai-chat hosts do).
        home: Scaffold(body: SafeArea(child: screen)),
      ),
    ),
  );
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

class _FakeAuthRepo extends Mock implements AuthRepository {}

class _FakeAiRepo extends Mock implements AiRepository {}

const _authedUser = AuthUser(
  id: 'u1',
  name: 'Tester',
  email: 't@example.com',
  avatar: '',
  provider: 'email',
);

AnalysisResult _minimal() => AnalysisResult(
  githubUsername: 'octo',
  leetcodeUsername: '',
  codeforcesHandle: '',
  github: GithubStats.empty('octo'),
  leetcode: null,
  codeforces: null,
  contributions: null,
  analyzedAt: DateTime(2026, 10, 1),
);

void main() {
  group('auth error mapping', () {
    test('backend 401s map to sign-in copy', () {
      expect(
        signInNeededMessage('Missing or invalid authorization'),
        contains('sign in'),
      );
      expect(
        signInNeededMessage('Invalid or expired session'),
        contains('sign in'),
      );
      expect(signInNeededMessage('plain network failure'), isNull);
    });
  });

  group('signed-out AI gates (no session token)', () {
    testWidgets('analyze AI panel gates', (t) async {
      await _pumpGated(t, AiInsightsPanel(result: _minimal()));
      expect(find.byType(SignInRequired), findsOneWidget);
      expect(find.text('Sign in required'), findsOneWidget);
      expect(find.text('Generate'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('review screen gates action, keeps editor', (t) async {
      await _pumpGated(t, const ReviewScreen());
      expect(find.byType(SignInRequired), findsOneWidget);
      expect(find.text('Review Code'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('ai chat gates conversation', (t) async {
      await _pumpGated(t, const AiScreen());
      expect(find.byType(SignInRequired), findsOneWidget);
      expect(find.text('Suggested prompts'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  group('signed-in AI panel idle', () {
    testWidgets('shows per-mode Generate button', (t) async {
      final repo = _FakeAuthRepo();
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => (user: _authedUser, token: 'tok'));
      final container = ProviderContainer(
        overrides: [authRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      // Drive the real controller to authenticated (login also covers
      // the secure-storage write path via its try/catch fallback).
      await container
          .read(authProvider.notifier)
          .login(email: 't@example.com', password: 'secret123');
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            darkTheme: DevIQTheme.dark(),
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: AiInsightsPanel(result: _minimal()),
                ),
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
      expect(find.text('Generate Quick Take'), findsOneWidget);
      expect(find.text('Generate all →'), findsOneWidget);
      expect(find.byType(SignInRequired), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('generated markdown renders bullets + bold', (t) async {
      final repo = _FakeAuthRepo();
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => (user: _authedUser, token: 'tok'));
      final ai = _FakeAiRepo();
      when(() => ai.insights(prompt: any(named: 'prompt'))).thenAnswer(
        (_) async => '- **Bold lead** with tail text\n\n- Second bullet here',
      );
      final container = ProviderContainer(
        overrides: [
          authRepoProvider.overrideWithValue(repo),
          aiRepoProvider.overrideWithValue(ai),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(authProvider.notifier)
          .login(email: 't@example.com', password: 'secret123');
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            darkTheme: DevIQTheme.dark(),
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: AiInsightsPanel(result: _minimal()),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Generate Quick Take'));
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      bool richContains(String s) {
        String collect(Object? span) {
          if (span is! TextSpan) return '';
          final b = StringBuffer(span.text ?? '');
          span.children?.forEach((c) => b.write(collect(c)));
          return b.toString();
        }

        return find
            .byWidgetPredicate((w) {
              if (w is RichText) return collect(w.text).contains(s);
              if (w is SelectableText) {
                return collect(w.textSpan).contains(s);
              }
              return false;
            })
            .evaluate()
            .isNotEmpty;
      }

      expect(richContains('Bold lead with tail text'), isTrue);
      expect(richContains('Second bullet here'), isTrue);
      // Bold span actually bold.
      final hasBold = find
          .byWidgetPredicate((w) {
            if (w is RichText) return _hasBold(w.text);
            if (w is SelectableText) return _hasBold(w.textSpan);
            return false;
          })
          .evaluate()
          .isNotEmpty;
      expect(hasBold, isTrue);
      expect(t.takeException(), isNull);
    });
  });

  chatConversationTests();
}

bool _hasBold(InlineSpan? span) {
  var found = false;
  void visit(TextSpan s) {
    if ((s.style?.fontWeight?.value ?? 0) >= FontWeight.w700.value &&
        (s.text ?? '').contains('Bold lead')) {
      found = true;
    }
    s.children?.whereType<TextSpan>().forEach(visit);
  }

  if (span is TextSpan) visit(span);
  return found;
}

/// Signed-in conversation in the web reference shape.
void chatConversationTests() {
  group('signed-in chat conversation', () {
    testWidgets('greeting, send flow, markdown answer, clear', (t) async {
      final repo = _FakeAuthRepo();
      when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => (user: _authedUser, token: 'tok'));
      final ai = _FakeAiRepo();
      when(
        () => ai.insights(
          prompt: any(named: 'prompt'),
          history: any(named: 'history'),
        ),
      ).thenAnswer(
        (_) async => '## Progress Summary\n\nSteady engagement shown.\n\n- **Fast start** keeps momentum\n- Review zero-point analyses',
      );
      final container = ProviderContainer(
        overrides: [
          authRepoProvider.overrideWithValue(repo),
          aiRepoProvider.overrideWithValue(ai),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(authProvider.notifier)
          .login(email: 't@example.com', password: 'secret123');
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            darkTheme: DevIQTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: SafeArea(child: AiScreen())),
          ),
        ),
      );
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      // Coach greeting with first name, suggestions visible.
      expect(find.textContaining('DevIQ coach'), findsOneWidget);
      expect(find.text('Summarize my progress'), findsOneWidget);
      expect(find.text('Clear chat'), findsNothing);
      // Send via suggestion pill.
      await t.tap(find.text('Summarize my progress'));
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      // Greeting replaced by the conversation; markdown answer rendered.
      expect(find.textContaining('DevIQ coach'), findsNothing);
      expect(find.textContaining('Fast start'), findsOneWidget);
      expect(find.text('Clear chat'), findsOneWidget);
      // Clear restores the greeting.
      await t.tap(find.text('Clear chat'));
      await t.pumpAndSettle();
      expect(find.textContaining('DevIQ coach'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
