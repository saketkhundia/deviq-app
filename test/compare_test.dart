import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/data/models/analysis_models.dart';
import 'package:deviq/data/models/github_models.dart';
import 'package:deviq/data/repositories/analysis_repository.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/compare/presentation/compare_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAnalysisRepo extends Mock implements AnalysisRepository {}

AnalysisResult _side(String u, int repos, int stars, double skill) =>
    AnalysisResult(
      githubUsername: u,
      leetcodeUsername: '',
      codeforcesHandle: '',
      github: GithubStats.fromJson(u, {
        'analytics': {
          'total_projects': repos,
          'total_stars': stars,
          'skill_score': skill,
          'most_used_language': 'Go',
          'language_distribution': {'Go': repos},
        },
        'repositories': [],
      }),
      leetcode: null,
      codeforces: null,
      contributions: null,
      analyzedAt: DateTime(2026, 10, 1),
    );

/// Compare results in the web reference shape: face-off rings, win
/// pills and dual-bar metric rows — no overflow at 360px.
void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('success renders web-style face-off at 360px', (t) async {
    final repo = _FakeAnalysisRepo();
    when(
      () => repo.analyze(
        github: any(named: 'github'),
        leetcode: any(named: 'leetcode'),
        codeforces: any(named: 'codeforces'),
      ),
    ).thenAnswer((inv) async {
      final gh = inv.namedArguments[const Symbol('github')] as String;
      return gh == 'aaa'
          ? _side('aaa', 47, 12981, 82)
          : _side('bbb', 35, 14, 31);
    });
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [analysisRepoProvider.overrideWithValue(repo)],
        child: MaterialApp(
          darkTheme: DevIQTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: SafeArea(child: CompareScreen())),
        ),
      ),
    );
    await t.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(fields.evaluate().length, 6);
    await t.enterText(fields.at(0), 'aaa');
    await t.enterText(fields.at(3), 'bbb');
    // Button sits below the fold: scroll the page first.
    await t.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
    await t.pumpAndSettle();
    await t.tap(find.text('Compare'));
    await t.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.textContaining('leads by'), findsOneWidget);
    expect(find.textContaining('wins'), findsNWidgets(2));
    expect(find.text('VS'), findsOneWidget);
    for (final label in [
      'Dev Score',
      'Repos',
      'Stars',
      'LC Solved',
      'LC Hard',
      'CF Rating',
      'CF Problems',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });
}
