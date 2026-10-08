import '../../core/utils/score_utils.dart';
import 'github_models.dart';
import 'platform_models.dart';

/// Unified analysis result combining all three platforms.
class AnalysisResult {
  const AnalysisResult({
    required this.githubUsername,
    required this.leetcodeUsername,
    required this.codeforcesHandle,
    required this.github,
    required this.leetcode,
    required this.codeforces,
    required this.contributions,
    required this.analyzedAt,
  });

  final String githubUsername;
  final String leetcodeUsername;
  final String codeforcesHandle;
  final GithubStats? github;
  final LeetcodeStats? leetcode;
  final CodeforcesStats? codeforces;
  final ContributionData? contributions;
  final DateTime analyzedAt;

  double? get githubScore => github == null
      ? null
      : github!.skillScore > 0
          ? github!.skillScore.clamp(0, 100)
          : ScoreUtils.githubScore(
              repos: github!.totalProjects,
              stars: github!.totalStars,
              languages: github!.languageDistribution.length);

  double? get leetcodeScore => leetcode == null
      ? null
      : ScoreUtils.leetcodeScore(
          solved: leetcode!.totalSolved,
          hard: leetcode!.hardSolved,
          ranking: leetcode!.ranking > 0 ? leetcode!.ranking : null);

  double? get codeforcesScore => codeforces == null
      ? null
      : ScoreUtils.codeforcesScore(
          rating: codeforces!.rating > 0 ? codeforces!.rating : null,
          contests: codeforces!.contestsParticipated,
          solved: codeforces!.problemsSolved);

  double get unifiedScore => ScoreUtils.unified(
        github: githubScore,
        leetcode: leetcodeScore,
        codeforces: codeforcesScore,
      );

  bool get hasData => github != null || leetcode != null || codeforces != null;

  Map<String, dynamic> toHistoryJson() => {
        'date': analyzedAt.toIso8601String(),
        'score': unifiedScore,
        'github': githubUsername,
        'leetcode': leetcodeUsername,
        'codeforces': codeforcesHandle,
        'stars': github?.totalStars ?? 0,
        'repos': github?.totalProjects ?? 0,
        'language': github?.mostUsedLanguage ?? '',
        'lcSolved': leetcode?.totalSolved ?? 0,
        'lcEasy': leetcode?.easySolved ?? 0,
        'lcMedium': leetcode?.mediumSolved ?? 0,
        'lcHard': leetcode?.hardSolved ?? 0,
        'cfRating': codeforces?.rating ?? 0,
        'cfRank': codeforces?.rank ?? '',
        'cfProblems': codeforces?.problemsSolved ?? 0,
        'cfContests': codeforces?.contestsParticipated ?? 0,
      };

  factory AnalysisResult.fromHistoryJson(Map<String, dynamic> j) =>
      throw UnsupportedError('History restores summary only');
}

/// Persisted lightweight history record.
class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.date,
    required this.score,
    required this.github,
    required this.leetcode,
    required this.codeforces,
    required this.stars,
    required this.repos,
    required this.language,
    required this.lcSolved,
    required this.lcEasy,
    required this.lcMedium,
    required this.lcHard,
    required this.cfRating,
    required this.cfRank,
    required this.cfProblems,
    required this.cfContests,
  });

  final String id;
  final DateTime date;
  final double score;
  final String github;
  final String leetcode;
  final String codeforces;
  final int stars;
  final int repos;
  final String language;
  final int lcSolved;
  final int lcEasy;
  final int lcMedium;
  final int lcHard;
  final int cfRating;
  final String cfRank;
  final int cfProblems;
  final int cfContests;

  factory HistoryRecord.fromJson(Map<String, dynamic> j) => HistoryRecord(
        id: parseString(j['id']),
        date: DateTime.tryParse(parseString(j['date'])) ?? DateTime.now(),
        score: parseDouble(j['score']),
        github: parseString(j['github']),
        leetcode: parseString(j['leetcode']),
        codeforces: parseString(j['codeforces']),
        stars: parseInt(j['stars']),
        repos: parseInt(j['repos']),
        language: parseString(j['language']),
        lcSolved: parseInt(j['lcSolved']),
        lcEasy: parseInt(j['lcEasy']),
        lcMedium: parseInt(j['lcMedium']),
        lcHard: parseInt(j['lcHard']),
        cfRating: parseInt(j['cfRating']),
        cfRank: parseString(j['cfRank']),
        cfProblems: parseInt(j['cfProblems']),
        cfContests: parseInt(j['cfContests']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'score': score,
        'github': github,
        'leetcode': leetcode,
        'codeforces': codeforces,
        'stars': stars,
        'repos': repos,
        'language': language,
        'lcSolved': lcSolved,
        'lcEasy': lcEasy,
        'lcMedium': lcMedium,
        'lcHard': lcHard,
        'cfRating': cfRating,
        'cfRank': cfRank,
        'cfProblems': cfProblems,
        'cfContests': cfContests,
      };
}
