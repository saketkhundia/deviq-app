import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/core/utils/weak_categories.dart';
import 'package:deviq/data/models/platform_models.dart';
import 'package:deviq/data/repositories/analysis_repository.dart';
import 'package:deviq/data/repositories/misc_repositories.dart';
import 'package:deviq/data/models/ai_models.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/interview_prep/presentation/interview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAnalysis extends Mock implements AnalysisRepository {}

class _FakeInterview extends Mock implements InterviewRepository {}

/// Interview prep in the web reference shape: username analyzer,
/// estimated weak-category cards, brand company grid and the selected
/// company panel with ring, search and trackable rows.
void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  group('weak category estimator', () {
    test('distributes solved across the topic table, weakest first', () {
      final cats = estimateWeakCategories(
        easySolved: 72,
        mediumSolved: 165,
        hardSolved: 34,
      );
      expect(cats.length, topicTable.length);
      for (var i = 1; i < cats.length; i++) {
        expect(
          cats[i].percent,
          greaterThanOrEqualTo(cats[i - 1].percent - 0.001),
        );
      }
      for (final c in cats) {
        expect(c.solved, inInclusiveRange(0, c.total));
        expect(c.percent, inInclusiveRange(0, 100));
      }
      final total = cats.fold<int>(0, (a, c) => a + c.solved);
      // Roughly conserves the solved pool (rounding tolerance).
      expect((total - 271).abs(), lessThanOrEqualTo(12));
    });

    test('zero input yields zeroed categories', () {
      final cats = estimateWeakCategories(
        easySolved: 0,
        mediumSolved: 0,
        hardSolved: 0,
      );
      expect(cats.every((c) => c.solved == 0), isTrue);
    });
  });

  group('leetcode model additions', () {
    test('parses contests + top percentage', () {
      final l = LeetcodeStats.fromJson('u', {
        'username': 'u',
        'total_solved': 271,
        'easy_solved': 72,
        'medium_solved': 165,
        'hard_solved': 34,
        'ranking': 588021,
        'reputation': 0,
        'contest_rating': 1433,
        'contests_attended': 2,
        'top_percentage': 69.57,
      });
      expect(l.contestsAttended, 2);
      expect(l.topPercentage, closeTo(69.57, 0.001));
    });
  });

  group('interview screen (mocked backend)', () {
    testWidgets('weak flow + company panel at 360px', (t) async {
      final analysis = _FakeAnalysis();
      when(() => analysis.leetcode(any())).thenAnswer(
        (_) async => LeetcodeStats.fromJson('neo', {
          'username': 'neo',
          'total_solved': 271,
          'easy_solved': 72,
          'medium_solved': 165,
          'hard_solved': 34,
          'ranking': 588021,
          'reputation': 0,
          'contest_rating': 1433,
          'contests_attended': 2,
          'top_percentage': 69.57,
        }),
      );
      final interview = _FakeInterview();
      when(() => interview.companyProblems(any())).thenAnswer(
        (_) async => [
          const CompanyProblem(
            id: 4401,
            slug: 'sum-of-decoded-numbers',
            title: 'Sum of Decoded Numbers',
            difficulty: 'Medium',
            url: 'https://leetcode.com/problems/sum-of-decoded-numbers/',
            paidOnly: false,
          ),
          const CompanyProblem(
            id: 4359,
            slug: 'min-ops',
            title: 'Minimum Operations',
            difficulty: 'Hard',
            url: '',
            paidOnly: true,
          ),
        ],
      );
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            analysisRepoProvider.overrideWithValue(analysis),
            interviewRepoProvider.overrideWithValue(interview),
          ],
          child: MaterialApp(
            darkTheme: DevIQTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: SafeArea(child: InterviewScreen())),
          ),
        ),
      );
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );
      expect(find.text('What Should You\nSolve Today?'), findsOneWidget);
      expect(find.text('YOUR WEAK CATEGORIES'), findsOneWidget);
      expect(find.text('COMPANY TAGS'), findsOneWidget);
      expect(find.text('Company-Tagged Problems'), findsOneWidget);
      expect(find.text('Google'), findsWidgets);
      // Analyze weak categories for the typed username.
      await t.enterText(
        find.widgetWithText(TextField, 'Enter your LeetCode username…'),
        'neo',
      );
      await t.tap(find.text('Analyze'));
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );
      expect(find.text('Graphs'), findsOneWidget);
      // Tier filter: Mid Tier hides FAANG cards, keeps Yahoo.
      await t.drag(
        find.ancestor(
          of: find.text('COMPANY TAGS'),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -1400),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Mid Tier'));
      await t.pumpAndSettle();
      expect(find.text('Yahoo'), findsOneWidget);
      // Grid hides Google; only the selected-company panel header remains.
      expect(find.text('Google').evaluate().length, 1);
      await t.tap(find.text('All Companies'));
      await t.pumpAndSettle();
      // Company panel loaded for default google.
      expect(find.textContaining('problems ·'), findsOneWidget);
      expect(find.text('#4401'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      // Difficulty filter narrows to Hard only.
      await t.drag(
        find.ancestor(
          of: find.text('COMPANY TAGS'),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -1200),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('diff-Hard')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('diff-Hard')));
      await t.pumpAndSettle();
      expect(find.text('Sum of Decoded Numbers'), findsNothing);
      expect(find.text('Minimum Operations'), findsOneWidget);
      // Solved toggle persists + updates counts.
      final boxes = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_CheckBox',
      );
      expect(boxes.evaluate().isNotEmpty, isTrue);
      await t.tap(boxes.first);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });
}
