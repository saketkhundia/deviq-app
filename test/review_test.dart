import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/data/models/ai_models.dart';
import 'package:deviq/data/models/auth_models.dart';
import 'package:deviq/data/repositories/ai_repository.dart';
import 'package:deviq/data/repositories/auth_repository.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/auth/presentation/auth_controller.dart';
import 'package:deviq/features/review/presentation/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepo extends Mock implements AuthRepository {}

class _FakeAiRepo extends Mock implements AiRepository {}

const _authedUser = AuthUser(
  id: 'u1',
  name: 'Tester',
  email: 't@example.com',
  avatar: '',
  provider: 'email',
);

/// Review page in the web reference shape: editor frame with toolbar +
/// footer, then summary, complexity, optimize, findings, quality,
/// suggestions and fixed code — no overflow at 360px.
void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('full review renders every web section at 360px', (t) async {
    final auth = _FakeAuthRepo();
    when(
      () => auth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => (user: _authedUser, token: 'tok'));
    final ai = _FakeAiRepo();
    when(
      () => ai.review(
        code: any(named: 'code'),
        language: any(named: 'language'),
      ),
    ).thenAnswer(
      (_) async => CodeReviewResult.fromJson({
        'summary': 'Uses print instead of console.log.',
        'score': 60,
        'bugs': [
          {
            'severity': 'HIGH',
            'title': "Undefined function 'print'",
            'line': 1,
            'category': 'undefined identifier confidence 100%',
            'detail': 'print is not a built-in function.',
            'trigger': 'Executing the script in any JS runtime.',
            'expected': 'Message should be output.',
            'actual': 'ReferenceError: print is not defined',
            'fix_explanation': 'Replace print with console.log.',
            'confidence': 100,
          },
        ],
        'warnings': [],
        'security': [],
        'suggestions': [
          {'title': 'Use strict mode', 'detail': 'Add use strict.'},
        ],
        'quality': [
          {'category': 'READABILITY', 'detail': 'Add a semicolon.'},
        ],
        'improvements': [],
        'time_complexity': {
          'value': 'O(1)',
          'explanation': 'Single operation.',
        },
        'space_complexity': {'value': 'O(1)', 'explanation': ''},
        'fixed_code': 'console.log("Hello World");',
        'repair_strategy': 'MINIMAL_FIX',
        'status': 'success',
      }),
    );
    when(
      () => ai.optimize(
        code: any(named: 'code'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => 'console.log("Hello World");');
    final container = ProviderContainer(
      overrides: [
        authRepoProvider.overrideWithValue(auth),
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
          home: const Scaffold(body: SafeArea(child: ReviewScreen())),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('AI CODE REVIEW'), findsOneWidget);
    expect(find.text('Try a sample'), findsOneWidget);
    await t.tap(find.text('Try a sample'));
    await t.pumpAndSettle();
    await t.drag(
      find.ancestor(
        of: find.text('AI CODE REVIEW'),
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(0, -900),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Review Code'));
    await t.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    for (final label in [
      'SUMMARY',
      'TIME COMPLEXITY',
      'SPACE COMPLEXITY',
      'OPTIMIZED TIME & SPACE',
      'BUGS',
      'WARNINGS',
      'SECURITY ISSUES',
      'CODE QUALITY',
      'SUGGESTIONS',
      'FIXED CODE',
      'MINIMAL FIX',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.textContaining("Undefined function 'print'"), findsOneWidget);
    // Optimize flow renders the improved code.
    await t.drag(
      find.ancestor(
        of: find.text('AI CODE REVIEW'),
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(0, -900),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Optimize'));
    await t.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    bool codeContains(String s) {
      String collect(Object? span) {
        if (span is TextSpan) {
          final b = StringBuffer(span.text ?? '');
          span.children?.forEach((c) => b.write(collect(c)));
          return b.toString();
        }
        return '';
      }

      return find
          .byWidgetPredicate((w) {
            if (w is RichText) return collect(w.text).contains(s);
            if (w is SelectableText) return collect(w.textSpan).contains(s);
            return false;
          })
          .evaluate()
          .isNotEmpty;
    }

    expect(codeContains('console.log'), isTrue);
    expect(codeContains('Hello World'), isTrue);
    expect(t.takeException(), isNull);
  });

  test('language auto-detect heuristics', () {
    expect(detectLanguageId('def f():\n    print("x")'), 'python');
    expect(detectLanguageId('console.log("x");'), 'javascript');
    expect(detectLanguageId('package main\nfunc main() {}'), 'go');
    expect(detectLanguageId('public class A {}'), 'java');
  });
}
