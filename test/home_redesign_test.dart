import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/data/models/analysis_models.dart';
import 'package:deviq/data/models/github_models.dart';
import 'package:deviq/data/models/platform_models.dart';
import 'package:deviq/features/analyze/presentation/analyze_controller.dart';
import 'package:deviq/features/home/presentation/home_screen.dart';
import 'package:deviq/features/home/presentation/widgets/feature_grid.dart';
import 'package:deviq/features/home/presentation/widgets/home_hero.dart';
import 'package:deviq/features/home/presentation/widgets/home_info.dart';
import 'package:deviq/features/home/presentation/widgets/next_step.dart';
import 'package:deviq/features/home/presentation/widgets/unified_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, double width) => ProviderScope(
  child: MaterialApp(
    theme: DevIQTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

void main() {
  for (final w in [375.0, 390.0, 430.0]) {
    testWidgets('home hero fits at ${w}px', (tester) async {
      tester.view.physicalSize = Size(w * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(const HomeHeroSection(), w));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.text('Compare Developers'), findsOneWidget);
      expect(find.text('Try Playground'), findsOneWidget);
      expect(find.text('Analyze Profile'), findsOneWidget);
    });

    testWidgets('onboarding score fits at ${w}px', (tester) async {
      tester.view.physicalSize = Size(w * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(const UnifiedScoreSection(), w));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.text('UNIFIED SCORE'), findsOneWidget);
      expect(find.text('No profile yet'), findsOneWidget);
    });
  }

  testWidgets('feature list + info fit at 375px', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 3000 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            FeatureList(entries: buildFeatureCards()),
            const HomeInfoSection(),
          ],
        ),
        375,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('live workspace states', () {
    AnalysisResult liveResult() {
      final days = <ContributionDay>[
        for (var i = 0; i < 120; i++)
          ContributionDay(
            date: DateTime.now()
                .subtract(Duration(days: 119 - i))
                .toIso8601String()
                .split('T')
                .first,
            count: i % 3 == 0 ? 0 : (i % 7) + 1,
            level: i % 5,
          ),
      ];
      return AnalysisResult(
        githubUsername: 'octo',
        leetcodeUsername: 'leet',
        codeforcesHandle: 'cf',
        github: const GithubStats(
          username: 'octo',
          totalProjects: 24,
          totalStars: 130,
          totalForks: 10,
          skillScore: 0,
          mostUsedLanguage: 'Dart',
          languageDistribution: {'Dart': 5, 'Python': 3, 'Go': 1},
          repositories: [],
        ),
        leetcode: const LeetcodeStats(
          username: 'leet',
          totalSolved: 412,
          easySolved: 200,
          mediumSolved: 150,
          hardSolved: 62,
          ranking: 45000,
          reputation: 0,
          contestRating: 0,
          globalRanking: 45000,
        ),
        codeforces: const CodeforcesStats(
          username: 'cf',
          rating: 1450,
          maxRating: 1600,
          rank: 'Specialist',
          maxRank: 'Expert',
          problemsSolved: 500,
          contestsParticipated: 32,
          contribution: 0,
        ),
        contributions: ContributionData(username: 'octo', days: days),
        analyzedAt: DateTime.now(),
      );
    }

    Future<void> pumpLive(
      WidgetTester tester,
      double width, {
      bool dark = true,
    }) async {
      tester.view.physicalSize = Size(width * 3, 3000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyzeProvider.overrideWith((ref) {
              final c = AnalyzeController(ref);
              c.state = AnalyzeState(
                status: AnalyzeStatus.success,
                result: liveResult(),
              );
              return c;
            }),
          ],
          child: MaterialApp(
            theme: DevIQTheme.light(),
            darkTheme: DevIQTheme.dark(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: const Scaffold(body: SafeArea(child: HomeScreen())),
          ),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
    }

    testWidgets('live score + fingerprint + skills at 375px', (tester) async {
      await pumpLive(tester, 375);
      expect(tester.takeException(), isNull);
      // Unified instrument with real verdict + platform ledger.
      expect(find.text('Mid-Level'), findsOneWidget);
      expect(find.text('GitHub'), findsWidgets);
      expect(find.text('LeetCode'), findsWidgets);
      expect(find.text('Codeforces'), findsWidgets);
      expect(find.text('First recorded analysis'), findsOneWidget);
      // Fingerprint with real stats.
      expect(find.text('CURRENT STREAK'), findsOneWidget);
      expect(find.text('LONGEST'), findsOneWidget);
      // Skill axes + role fit.
      expect(find.text('Engineering activity'), findsOneWidget);
      expect(find.text('Problem solving'), findsOneWidget);
      expect(find.text('Competitive programming'), findsOneWidget);
      expect(find.text('Consistency'), findsOneWidget);
      expect(find.textContaining('Best fit:'), findsOneWidget);
      // Weakest axis is Codeforces → AI plan directive.
      expect(find.text('Follow a 7-day improvement plan'), findsOneWidget);
      expect(find.text('Get my plan'), findsOneWidget);
    });

    testWidgets('live workspace at 430px light', (tester) async {
      await pumpLive(tester, 430, dark: false);
      expect(tester.takeException(), isNull);
      expect(find.text('Mid-Level'), findsOneWidget);
    });

    testWidgets('live workspace two-column at 1000px', (tester) async {
      await pumpLive(tester, 1000);
      expect(tester.takeException(), isNull);
      expect(find.text('Mid-Level'), findsOneWidget);
      expect(find.text('Consistency'), findsOneWidget);
    });
  });

  group('deriveNextStep', () {
    AnalysisResult result({
      GithubStats? github,
      LeetcodeStats? leetcode,
      CodeforcesStats? codeforces,
    }) => AnalysisResult(
      githubUsername: github == null ? '' : 'octo',
      leetcodeUsername: leetcode == null ? '' : 'leet',
      codeforcesHandle: codeforces == null ? '' : 'cf',
      github: github,
      leetcode: leetcode,
      codeforces: codeforces,
      contributions: null,
      analyzedAt: DateTime.now(),
    );

    GithubStats gh({int repos = 30, int stars = 500}) => GithubStats(
      username: 'octo',
      totalProjects: repos,
      totalStars: stars,
      totalForks: 0,
      skillScore: 80,
      mostUsedLanguage: 'Dart',
      languageDistribution: const {'Dart': 8},
      repositories: const [],
    );

    LeetcodeStats lc({int solved = 600, int hard = 150}) => LeetcodeStats(
      username: 'leet',
      totalSolved: solved,
      easySolved: solved - hard - 100,
      mediumSolved: 100,
      hardSolved: hard,
      ranking: 1000,
      reputation: 0,
      contestRating: 0,
      globalRanking: 1000,
    );

    CodeforcesStats cf({int rating = 2400}) => CodeforcesStats(
      username: 'cf',
      rating: rating,
      maxRating: rating,
      rank: 'Grandmaster',
      maxRank: 'Grandmaster',
      problemsSolved: 800,
      contestsParticipated: 60,
      contribution: 0,
    );

    HistoryRecord lastRec() => HistoryRecord(
      id: 'h1',
      date: DateTime.now().subtract(const Duration(days: 40)),
      score: 61,
      github: 'octo',
      leetcode: 'leet',
      codeforces: 'cf',
      stars: 10,
      repos: 12,
      language: 'Dart',
      lcSolved: 200,
      lcEasy: 100,
      lcMedium: 80,
      lcHard: 20,
      cfRating: 1400,
      cfRank: 'Specialist',
      cfProblems: 300,
      cfContests: 20,
    );

    test('onboarding when nothing exists', () {
      final d = deriveNextStep(
        result: null,
        last: null,
        failedPlatforms: const [],
      );
      expect(d.route, '/analyze');
      expect(d.action, 'Start analysis');
    });

    test('retries failed platforms first', () {
      final d = deriveNextStep(
        result: result(github: gh(), leetcode: lc(), codeforces: cf()),
        last: null,
        failedPlatforms: const ['LeetCode'],
      );
      expect(d.title, contains('LeetCode'));
      expect(d.route, '/analyze');
    });

    test('refreshes stale history', () {
      final d = deriveNextStep(
        result: null,
        last: lastRec(),
        failedPlatforms: const [],
      );
      expect(d.title, 'Refresh your profile');
      expect(d.route, '/analyze');
    });

    test('connects the missing platform', () {
      final d = deriveNextStep(
        result: result(github: gh(), leetcode: lc()),
        last: null,
        failedPlatforms: const [],
      );
      expect(d.title, 'Connect Codeforces');
      expect(d.route, '/analyze');
    });

    test('drills weakest LeetCode axis via interview prep', () {
      final d = deriveNextStep(
        result: result(
          github: gh(),
          leetcode: lc(solved: 30, hard: 0),
          codeforces: cf(),
        ),
        last: null,
        failedPlatforms: const [],
      );
      expect(d.route, '/interview');
      expect(d.title, startsWith('Drill'));
    });

    test('plans weakest Codeforces axis via AI', () {
      final d = deriveNextStep(
        result: result(
          github: gh(),
          leetcode: lc(),
          codeforces: cf(rating: 900),
        ),
        last: null,
        failedPlatforms: const [],
      );
      expect(d.route, '/ai');
    });

    test('reviews weakest GitHub axis via AI review', () {
      final d = deriveNextStep(
        result: result(
          github: gh(repos: 1, stars: 0),
          leetcode: lc(),
          codeforces: cf(),
        ),
        last: null,
        failedPlatforms: const [],
      );
      expect(d.route, '/review');
    });
  });
}
