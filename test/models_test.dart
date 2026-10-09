import 'package:deviq/data/models/ai_models.dart';
import 'package:deviq/data/models/analysis_models.dart';
import 'package:deviq/data/models/auth_models.dart';
import 'package:deviq/data/models/github_models.dart';
import 'package:deviq/data/models/platform_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GithubStats parsing (real /analyze shape)', () {
    test('aggregates repos, stars, languages', () {
      final g = GithubStats.fromJson('octocat', {
        'analytics': {
          'total_projects': 8,
          'total_stars': 22293,
          'skill_score': 100,
          'most_used_language': 'Ruby',
          'language_distribution': {'Ruby': 1, 'CSS': 1, 'HTML': 1},
        },
        'repositories': [
          {
            'name': 'r1',
            'full_name': 'o/r1',
            'html_url': 'https://github.com/o/r1',
            'description': 'x',
            'language': 'Ruby',
            'stargazers_count': 100,
            'forks_count': 5,
            'topics': ['a'],
            'updated_at': '2026-01-01T00:00:00Z',
            'private': false,
            'fork': false,
          },
        ],
      });
      expect(g.username, 'octocat');
      expect(g.totalStars, 22293);
      expect(g.skillScore, 100);
      expect(g.mostUsedLanguage, 'Ruby');
      expect(g.languageDistribution['CSS'], 1);
      expect(g.repositories.single.stars, 100);
      expect(g.totalForks, 5);
    });
  });

  group('LeetcodeStats parsing (real /leetcode shape)', () {
    test('handles flat response', () {
      final l = LeetcodeStats.fromJson('leetcode', {
        'username': 'LeetCode',
        'total_solved': 45,
        'easy_solved': 12,
        'medium_solved': 22,
        'hard_solved': 11,
        'ranking': 2927610,
        'reputation': 78113,
      });
      expect(l.totalSolved, 45);
      expect(l.hardSolved, 11);
      expect(l.ranking, 2927610);
    });
  });

  group('CodeforcesStats parsing (real /codeforces shape)', () {
    test('handles flat response', () {
      final c = CodeforcesStats.fromJson('tourist', {
        'username': 'tourist',
        'rating': 3384,
        'max_rating': 4009,
        'rank': 'legendary grandmaster',
        'problems_solved': 0,
        'contests_participated': 308,
        'contribution': 111,
      });
      expect(c.rating, 3384);
      expect(c.rank, 'legendary grandmaster');
      expect(c.contestsParticipated, 308);
    });
  });

  group('ContributionData', () {
    test('streak math', () {
      final d = ContributionData.fromJson('u', {
        'contributions': [
          {'date': '2026-01-01', 'count': 3, 'level': 2},
          {'date': '2026-01-02', 'count': 1, 'level': 1},
          {'date': '2026-01-03', 'count': 0, 'level': 0},
          {'date': '2026-01-04', 'count': 2, 'level': 1},
          {'date': '2026-01-05', 'count': 4, 'level': 3},
        ],
      });
      expect(d.total, 10);
      expect(d.longestStreak, 2);
      expect(d.currentStreak, 2);
    });
  });

  group('AnalysisResult scoring', () {
    test('unified blends platform scores', () {
      final r = AnalysisResult(
        githubUsername: 'g',
        leetcodeUsername: 'l',
        codeforcesHandle: 'c',
        github: GithubStats.empty('g'),
        leetcode: const LeetcodeStats(
          username: 'l',
          totalSolved: 300,
          easySolved: 100,
          mediumSolved: 150,
          hardSolved: 50,
          ranking: 50000,
          reputation: 100,
          contestRating: 0,
          globalRanking: 0,
        ),
        codeforces: const CodeforcesStats(
          username: 'c',
          rating: 1600,
          maxRating: 1700,
          rank: 'expert',
          maxRank: 'expert',
          problemsSolved: 200,
          contestsParticipated: 20,
          contribution: 5,
        ),
        contributions: null,
        analyzedAt: DateTime(2026, 1, 1),
      );
      expect(r.hasData, isTrue);
      expect(r.unifiedScore, inInclusiveRange(1, 100));
      final h = r.toHistoryJson();
      expect(h['github'], 'g');
      final rec = HistoryRecord.fromJson({'id': 'x', ...h});
      expect(rec.repos, 0);
      expect(rec.lcSolved, 300);
      expect(rec.toJson()['id'], 'x');
    });
  });

  group('Auth + profile models', () {
    test('parse safe fields', () {
      final u = AuthUser.fromJson({
        'id': '1',
        'name': 'A',
        'email': 'a@b.c',
        'provider': 'email',
      });
      expect(u.email, 'a@b.c');
      final p = UserProfile.fromJson({
        'displayName': 'A',
        'github_username': 'gh',
      });
      expect(p.githubUsername, 'gh');
      expect(p.copyWith(bio: 'hi').bio, 'hi');
      expect(UserProfile.empty().analysesRun, 0);
    });
  });

  group('AI models', () {
    test('review/issues/chat/problems/execution parse', () {
      final r = CodeReviewResult.fromJson({
        'summary': 'Looks good',
        'score': 82,
        'bugs': [
          {'title': 'Off-by-one', 'detail': 'fix loop'},
        ],
        'warnings': ['unused var'],
        'security_issues': [],
        'suggestions': ['add tests'],
        'time_complexity': 'O(n)',
        'space_complexity': 'O(1)',
        'fixed_code': 'x=1',
      });
      expect(r.issues.length, 2);
      expect(r.timeComplexity.value, 'O(n)');
      expect(r.suggestions.single.display, 'add tests');
      final m = ChatMessage(role: 'user', content: 'hi');
      expect(m.toJson()['role'], 'user');
      final cp = CompanyProblem.fromJson({
        'slug': 'a',
        'title': 'T',
        'difficulty': 'Easy',
        'url': 'u',
      });
      expect(cp.difficulty, 'Easy');
      final e = ExecutionResult.fromJson({
        'output': 'hi',
        'exit_code': 0,
        'elapsed_ms': 12,
      });
      expect(e.success, isTrue);
    });

    test('review parses the live backend shape', () {
      final r = CodeReviewResult.fromJson({
        'summary': 'Uses print instead of console.log.',
        'score': 95,
        'bugs': [
          {
            'severity': 'MEDIUM',
            'title': 'Incorrect language for JavaScript context',
            'line': 1,
            'category': 'language mismatch',
            'detail': 'print is not valid JavaScript.',
            'trigger': 'Running in a JS engine',
            'expected': 'console.log output',
            'actual': 'SyntaxError',
            'fix_explanation': 'Replace print with console.log.',
            'confidence': 100,
          },
        ],
        'warnings': [],
        'security': [],
        'suggestions': [
          {'title': 'Add file header comment', 'detail': 'Describe purpose.'},
        ],
        'quality': [
          {'category': 'READABILITY', 'detail': 'Clear and concise.'},
        ],
        'improvements': [],
        'time_complexity': {
          'value': 'O(1)',
          'explanation': 'Single constant-time operation.',
        },
        'space_complexity': {
          'value': 'O(1)',
          'explanation': 'No extra allocation.',
        },
        'fixed_code': 'console.log("Hello World");',
        'repair_strategy': 'MINIMAL_FIX',
        'status': 'success',
      });
      final bug = r.bugs.single;
      expect(bug.line, 1);
      expect(bug.trigger, contains('JS engine'));
      expect(bug.expected, contains('console.log'));
      expect(bug.actual, 'SyntaxError');
      expect(bug.fix, contains('console.log'));
      expect(bug.confidence, 100);
      expect(r.timeComplexity.value, 'O(1)');
      expect(r.timeComplexity.explanation, contains('constant-time'));
      expect(r.quality.single.title, 'READABILITY');
      expect(r.suggestions.single.display, contains('Add file header'));
      expect(r.repairStrategy, 'MINIMAL FIX');
      expect(r.fixedCode, contains('console.log'));
    });
  });
}
