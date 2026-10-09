import 'package:deviq/core/errors/api_exception.dart';
import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/core/utils/role_fit.dart';
import 'package:deviq/data/models/analysis_models.dart';
import 'package:deviq/data/models/github_models.dart';
import 'package:deviq/data/models/platform_models.dart';
import 'package:deviq/data/models/repo_models.dart';
import 'package:deviq/data/repositories/analysis_repository.dart';
import 'package:deviq/features/analyze/presentation/analyze_screen.dart';
import 'package:deviq/features/analyze/presentation/insights_controller.dart';
import 'package:deviq/features/analyze/presentation/widgets/share_card.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAnalysisRepo extends Mock implements AnalysisRepository {}

AnalysisResult _canned() {
  final gh = GithubStats.fromJson('octo', {
    'analytics': {
      'total_projects': 12,
      'total_stars': 340,
      'skill_score': 72,
      'most_used_language': 'TypeScript',
      'language_distribution': {'TypeScript': 5, 'Python': 3, 'Go': 1},
    },
    'repositories': [
      {
        'name': 'web',
        'full_name': 'octo/web',
        'html_url': 'https://github.com/octo/web',
        'description': 'A web app',
        'language': 'TypeScript',
        'stargazers_count': 200,
        'forks_count': 20,
        'topics': ['web', 'app'],
        'updated_at': '2026-09-01T00:00:00Z',
        'private': false,
        'fork': false,
        'size': 4200,
        'open_issues_count': 4,
      },
      {
        'name': 'api',
        'full_name': 'octo/api',
        'html_url': 'https://github.com/octo/api',
        'description': 'API service',
        'language': 'Go',
        'stargazers_count': 40,
        'forks_count': 5,
        'topics': ['api'],
        'updated_at': '2026-08-01T00:00:00Z',
        'private': false,
        'fork': false,
        'size': 900,
        'open_issues_count': 1,
      },
    ],
  });
  final lc = LeetcodeStats.fromJson('octo', {
    'username': 'octo',
    'total_solved': 320,
    'easy_solved': 120,
    'medium_solved': 150,
    'hard_solved': 50,
    'ranking': 42000,
    'reputation': 210,
  });
  final cf = CodeforcesStats.fromJson('octo', {
    'username': 'octo',
    'rating': 1650,
    'max_rating': 1720,
    'rank': 'expert',
    'max_rank': 'expert',
    'problems_solved': 180,
    'contests_participated': 22,
    'contribution': 6,
  });
  final contrib = ContributionData.fromJson('octo', {
    'contributions': [
      for (var i = 0; i < 35; i++)
        {
          'date': '2026-08-${(i % 28 + 1).toString().padLeft(2, '0')}',
          'count': i % 5,
          'level': i % 5,
        },
    ],
  });
  return AnalysisResult(
    githubUsername: 'octo',
    leetcodeUsername: 'octo',
    codeforcesHandle: 'octo',
    github: gh,
    leetcode: lc,
    codeforces: cf,
    contributions: contrib,
    analyzedAt: DateTime(2026, 10, 1),
  );
}

Future<void> _runAnalysis(WidgetTester t) async {
  await t.enterText(find.widgetWithText(TextFormField, 'torvalds'), 'octo');
  await t.tap(find.text('Run Analysis'));
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 15),
  );
}

void main() {
  setUpAll(() {
    // Official unit-test backing for shared_preferences: instant,
    // hermetic, and exercises the real (non-fallback) storage path.
    SharedPreferences.setMockInitialValues({});
  });

  group('role fit (derived estimates)', () {
    test('frontend-heavy profile favors frontend/full-stack', () {
      final r = AnalysisResult(
        githubUsername: 'fe',
        leetcodeUsername: '',
        codeforcesHandle: '',
        github: GithubStats.fromJson('fe', {
          'analytics': {
            'total_projects': 20,
            'total_stars': 120,
            'skill_score': 60,
            'most_used_language': 'TypeScript',
            'language_distribution': {
              'TypeScript': 8,
              'JavaScript': 5,
              'HTML': 3,
              'CSS': 3,
            },
          },
          'repositories': [],
        }),
        leetcode: null,
        codeforces: null,
        contributions: null,
        analyzedAt: DateTime(2026, 1, 1),
      );
      final fits = estimateRoleFit(r);
      expect(fits, isNotEmpty);
      expect(fits.first.role, 'Frontend Developer');
    });

    test('leetcode/codeforces-heavy profile favors competitive', () {
      final fits = estimateRoleFit(_canned());
      expect(fits, isNotEmpty);
      expect(fits.first.role, 'Competitive Programmer');
    });

    test('competitive profile favors competitive programmer', () {
      final r = AnalysisResult(
        githubUsername: '',
        leetcodeUsername: 'cp',
        codeforcesHandle: 'cp',
        github: null,
        leetcode: const LeetcodeStats(
          username: 'cp',
          totalSolved: 900,
          easySolved: 100,
          mediumSolved: 400,
          hardSolved: 400,
          ranking: 500,
          reputation: 2000,
          contestRating: 2300,
          globalRanking: 500,
        ),
        codeforces: const CodeforcesStats(
          username: 'cp',
          rating: 2400,
          maxRating: 2500,
          rank: 'grandmaster',
          maxRank: 'grandmaster',
          problemsSolved: 1200,
          contestsParticipated: 90,
          contribution: 30,
        ),
        contributions: null,
        analyzedAt: DateTime(2026, 1, 1),
      );
      final fits = estimateRoleFit(r);
      expect(fits.first.role, 'Competitive Programmer');
    });

    test('empty result yields no fits', () {
      final r = AnalysisResult(
        githubUsername: 'x',
        leetcodeUsername: '',
        codeforcesHandle: '',
        github: GithubStats.empty('x'),
        leetcode: null,
        codeforces: null,
        contributions: null,
        analyzedAt: DateTime(2026, 1, 1),
      );
      expect(estimateRoleFit(r), isEmpty);
    });
  });

  group('repo tree model (live shape)', () {
    test('parses flat entries and builds hierarchy', () {
      final tree = RepoTree.fromJson({
        'owner': 'octocat',
        'repo': 'Hello-World',
        'branch': 'master',
        'truncated': false,
        'total_files': 3,
        'total_dirs': 1,
        'entries': [
          {'path': 'README', 'type': 'blob'},
          {'path': 'src/main.py', 'type': 'blob'},
          {'path': 'src/util.py', 'type': 'blob'},
          {'path': 'src', 'type': 'tree'},
        ],
      });
      expect(tree.totalFiles, 3);
      final root = tree.root;
      expect(root.children.length, 2); // README + src/
      final src = root.child('src')!;
      expect(src.isDir, isTrue);
      expect(src.children.length, 2);
    });
  });

  group('report export + prompts', () {
    test('markdown contains real values', () {
      final md = buildReportMarkdown(_canned());
      expect(md, contains('octo'));
      expect(md, contains('340'));
      expect(md, contains('## LeetCode'));
      expect(md, contains('## Codeforces'));
      expect(md, contains('1650'));
    });

    test('insight prompts embed profile + hindi flag', () {
      final en = insightPrompt(InsightMode.plan, _canned());
      expect(en, contains('7-day'));
      expect(en, contains('octo'));
      final hi = insightPrompt(InsightMode.quick, _canned(), hindi: true);
      expect(hi, contains('Hindi'));
    });
  });

  group('analyze screen states (mocked backend)', () {
    late _FakeAnalysisRepo repo;

    setUp(() {
      repo = _FakeAnalysisRepo();
      registerFallbackValue(InsightMode.quick);
    });

    Future<void> pump(WidgetTester t) async {
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
            home: const Scaffold(body: SafeArea(child: AnalyzeScreen())),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('success renders all sections at 360px', (t) async {
      when(
        () => repo.analyze(
          github: any(named: 'github'),
          leetcode: any(named: 'leetcode'),
          codeforces: any(named: 'codeforces'),
        ),
      ).thenAnswer((_) async => _canned());
      await pump(t);
      await _runAnalysis(t);
      expect(find.text('ANALYSIS REPORT'), findsOneWidget);
      expect(find.text('PLATFORMS'), findsOneWidget);
      expect(find.text('AI INSIGHTS'), findsOneWidget);
      expect(find.text('ACTIVITY'), findsOneWidget);
      expect(find.text('GitHub Insights'), findsOneWidget);
      expect(find.text('ADVANCED'), findsOneWidget);
      expect(find.text('WHICH ROLE FITS YOU BEST?'), findsOneWidget);
      expect(find.text('REPOSITORIES'), findsWidgets);
      expect(find.text('DEVIQ REPORT'), findsOneWidget);
      expect(find.text('MOST COMPLEX REPO'), findsOneWidget);
      // Search + sort controls present and functional surface.
      await t.enterText(
        find.widgetWithText(TextField, 'Search repositories…'),
        'web',
      );
      await t.pumpAndSettle();
      expect(find.textContaining('web'), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('backend failure shows human error, no red screen', (t) async {
      when(
        () => repo.analyze(
          github: any(named: 'github'),
          leetcode: any(named: 'leetcode'),
          codeforces: any(named: 'codeforces'),
        ),
      ).thenThrow(
        const ApiException(
          ApiErrorKind.notFound,
          'Not found. Check the username.',
        ),
      );
      await pump(t);
      await _runAnalysis(t);
      expect(find.textContaining('Not found'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
