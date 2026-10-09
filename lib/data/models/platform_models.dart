import 'github_models.dart';

/// LeetCode profile from GET /leetcode/{u}.
class LeetcodeStats {
  const LeetcodeStats({
    required this.username,
    required this.totalSolved,
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.ranking,
    required this.reputation,
    required this.contestRating,
    required this.globalRanking,
    this.contestsAttended = 0,
    this.topPercentage = 0,
  });

  final String username;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int ranking;
  final int reputation;
  final int contestRating;
  final int globalRanking;

  /// Contests attended (backend `contests_attended`, 0 when absent).
  final int contestsAttended;

  /// Global top percentile (backend `top_percentage`, 0 when absent).
  final double topPercentage;

  factory LeetcodeStats.fromJson(String username, Map<String, dynamic> j) {
    final contest = asMap(j['contest']);
    return LeetcodeStats(
      username: parseString(j['username']).isEmpty
          ? username
          : parseString(j['username']),
      totalSolved: parseInt(j['total_solved'] ?? j['solved']),
      easySolved: parseInt(j['easy_solved'] ?? j['easy']),
      mediumSolved: parseInt(j['medium_solved'] ?? j['medium']),
      hardSolved: parseInt(j['hard_solved'] ?? j['hard']),
      ranking: parseInt(j['ranking']),
      reputation: parseInt(j['reputation']),
      contestRating: parseInt(
        j['contest_rating'] ?? contest['rating'] ?? j['contestRating'],
      ),
      globalRanking: parseInt(
        j['global_ranking'] ?? contest['global_ranking'] ?? j['ranking'],
      ),
      contestsAttended: parseInt(
        j['contests_attended'] ?? contest['count'] ?? contest['attended'],
      ),
      topPercentage: parseDouble(j['top_percentage'] ?? j['topPercentile']),
    );
  }
}

/// Codeforces profile from GET /codeforces/{u}.
class CodeforcesStats {
  const CodeforcesStats({
    required this.username,
    required this.rating,
    required this.maxRating,
    required this.rank,
    required this.maxRank,
    required this.problemsSolved,
    required this.contestsParticipated,
    required this.contribution,
  });

  final String username;
  final int rating;
  final int maxRating;
  final String rank;
  final String maxRank;
  final int problemsSolved;
  final int contestsParticipated;
  final int contribution;

  factory CodeforcesStats.fromJson(String username, Map<String, dynamic> j) =>
      CodeforcesStats(
        username: parseString(j['username']).isEmpty
            ? username
            : parseString(j['username']),
        rating: parseInt(j['rating']),
        maxRating: parseInt(j['max_rating'] ?? j['maxRating']),
        rank: parseString(j['rank']),
        maxRank: parseString(j['max_rank'] ?? j['maxRank']),
        problemsSolved: parseInt(j['problems_solved'] ?? j['problemsSolved']),
        contestsParticipated: parseInt(
          j['contests_participated'] ?? j['contestsParticipated'],
        ),
        contribution: parseInt(j['contribution']),
      );
}

/// Single contribution-calendar day from GET /contributions/{u}.
class ContributionDay {
  const ContributionDay({
    required this.date,
    required this.count,
    required this.level,
  });
  final String date;
  final int count;
  final int level;

  factory ContributionDay.fromJson(Map<String, dynamic> j) => ContributionDay(
    date: parseString(j['date']),
    count: parseInt(j['count']),
    level: parseInt(j['level']),
  );
}

class ContributionData {
  const ContributionData({required this.username, required this.days});
  final String username;
  final List<ContributionDay> days;

  factory ContributionData.fromJson(String username, dynamic json) {
    final map = asMap(json);
    final list = asList(map['contributions'] ?? json);
    return ContributionData(
      username: username,
      days: list
          .whereType<Map<String, dynamic>>()
          .map(ContributionDay.fromJson)
          .toList(),
    );
  }

  int get total => days.fold(0, (a, d) => a + d.count);

  int get currentStreak {
    var s = 0;
    for (var i = days.length - 1; i >= 0; i--) {
      if (days[i].count > 0) {
        s++;
      } else if (s > 0 || i < days.length - 1) {
        break;
      }
    }
    return s;
  }

  int get longestStreak {
    var best = 0, cur = 0;
    for (final d in days) {
      if (d.count > 0) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
    }
    return best;
  }
}
