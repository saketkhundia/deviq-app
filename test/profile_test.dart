import 'dart:convert';

import 'package:deviq/core/storage/app_storage.dart';
import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/data/models/analysis_models.dart';
import 'package:deviq/data/models/auth_models.dart';
import 'package:deviq/data/repositories/misc_repositories.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/profile/presentation/profile_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProfileRepo extends Mock implements ProfileRepository {}

HistoryRecord _rec(
  String id,
  int daysAgo,
  double score, {
  String gh = 'octo',
  int stars = 10,
  int repos = 12,
  int solved = 200,
  int hard = 20,
  int cf = 1400,
}) => HistoryRecord(
  id: id,
  date: DateTime.now().subtract(Duration(days: daysAgo)),
  score: score,
  github: gh,
  leetcode: 'leet',
  codeforces: 'cf',
  stars: stars,
  repos: repos,
  language: 'Dart',
  lcSolved: solved,
  lcEasy: solved - 100 - hard,
  lcMedium: 100,
  lcHard: hard,
  cfRating: cf,
  cfRank: 'Specialist',
  cfProblems: 300,
  cfContests: 20,
);

/// Profile in the reference shape: cover + identity + stat lenses,
/// about, score, platform connections, details, recent analyses with
/// pagination, progress chart, account rows — no overflow.
void main() {
  late _FakeProfileRepo profiles;

  setUp(() {
    profiles = _FakeProfileRepo();
    when(() => profiles.fetch()).thenAnswer((_) async => UserProfile.empty());
    when(
      () => profiles.connectedAccounts(),
    ).thenAnswer((_) async => <String, bool>{});
  });

  Future<void> pumpProfile(
    WidgetTester t, {
    List<HistoryRecord> history = const [],
    double width = 390,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (history.isNotEmpty)
        'deviq.history.records': [
          for (final h in history) jsonEncode(h.toJson()),
        ],
    });
    final prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = Size(width * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepoProvider.overrideWithValue(profiles),
          prefsStoreProvider.overrideWithValue(PrefsStore(prefs: prefs)),
        ],
        child: MaterialApp(
          darkTheme: DevIQTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: SafeArea(child: ProfileScreen())),
        ),
      ),
    );
    await t.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
  }

  group('profile reference layout', () {
    testWidgets('empty state renders every section', (t) async {
      await pumpProfile(t);
      expect(t.takeException(), isNull);
      expect(find.text('Guest'), findsOneWidget);
      for (final h in [
        'Analyses Run',
        'Comparisons',
        'AI Insights',
        'ABOUT',
        'DEVIQ SCORE',
        'PLATFORM CONNECTIONS',
        'PROFILE DETAILS',
        'RECENT ANALYSES',
        'PROGRESS OVER TIME',
      ]) {
        expect(find.text(h), findsOneWidget, reason: 'missing $h');
      }
      expect(find.text('No bio yet.'), findsOneWidget);
      expect(find.text('Run Analysis'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
      for (final label in ['History', 'Settings', 'Logout', 'Delete account']) {
        expect(find.text(label), findsOneWidget);
      }
      // Honest empties, no fabricated numbers.
      expect(find.textContaining('No analyses yet'), findsOneWidget);
      expect(find.text('No data yet — analyses you run will chart here.'),
          findsOneWidget);
    });

    testWidgets('history drives score, recent log and chart', (t) async {
      await pumpProfile(t, history: [
        _rec('h1', 1, 78, stars: 130, repos: 24, solved: 412, hard: 62),
        _rec('h2', 9, 61.5),
        _rec('h3', 40, 44),
      ]);
      expect(t.takeException(), isNull);
      expect(find.text('3 total'), findsOneWidget);
      expect(find.textContaining('Senior'), findsOneWidget);
      expect(find.text('octo'), findsWidgets);
      expect(find.text('78.0'), findsWidgets);
      expect(find.byType(LineChart), findsOneWidget);
      for (final label in ['FIRST', 'LATEST', 'CHANGE']) {
        expect(find.text(label), findsOneWidget);
      }
      // LeetCode tab recomputes from stored totals. The platform row
      // shares the label, so tap the later (tab chip) match.
      final lcLabels = find.text('LeetCode').evaluate().toList();
      expect(lcLabels.length, 2);
      await t.tapAt(
        t.getCenter(find.byElementPredicate((e) => e == lcLabels.last)),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('recent log paginates then reveals all', (t) async {
      await pumpProfile(t, history: [
        for (var i = 0; i < 7; i++) _rec('h$i', i, 50 + i * 2.0),
      ]);
      expect(find.text('7 total'), findsOneWidget);
      expect(find.text('Load More (2 remaining) →'), findsOneWidget);
      await t.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
      await t.pumpAndSettle();
      await t.tap(find.text('Load More (2 remaining) →'));
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      expect(find.text('Load More (2 remaining) →'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('two-column workspace at 1000px', (t) async {
      await pumpProfile(t, width: 1000, history: [_rec('h1', 2, 70)]);
      expect(t.takeException(), isNull);
      expect(find.text('PLATFORM CONNECTIONS'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });
  });
}
