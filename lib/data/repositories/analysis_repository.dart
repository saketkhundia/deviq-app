import '../../core/networking/api_client.dart';
import '../models/analysis_models.dart';
import '../models/github_models.dart';
import '../models/platform_models.dart';

/// Read-only analytics endpoints. Each platform fetch is independent so a
/// single failure never blocks the others (handled per-call upstream).
class AnalysisRepository {
  AnalysisRepository(this._api);
  final ApiClient _api;

  Future<GithubStats> github(String username) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/analyze/$username',
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return GithubStats.fromJson(username, json);
  }

  Future<LeetcodeStats> leetcode(String username) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/leetcode/$username',
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return LeetcodeStats.fromJson(username, json);
  }

  Future<CodeforcesStats> codeforces(String handle) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/codeforces/$handle',
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return CodeforcesStats.fromJson(handle, json);
  }

  Future<ContributionData> contributions(String username) async {
    final data = await _api.get<dynamic>('/contributions/$username');
    return ContributionData.fromJson(username, data);
  }

  /// Combined result; nulls mark platforms that were skipped or failed.
  Future<AnalysisResult> analyze({
    String github = '',
    String leetcode = '',
    String codeforces = '',
  }) async {
    GithubStats? gh;
    LeetcodeStats? lc;
    CodeforcesStats? cf;
    ContributionData? contrib;

    if (github.isNotEmpty) {
      try {
        gh = await this.github(github);
      } catch (_) {
        gh = null;
      }
      if (gh != null) {
        try {
          contrib = await contributions(github);
        } catch (_) {
          contrib = null;
        }
      }
    }
    if (leetcode.isNotEmpty) {
      try {
        lc = await this.leetcode(leetcode);
      } catch (_) {
        lc = null;
      }
    }
    if (codeforces.isNotEmpty) {
      try {
        cf = await this.codeforces(codeforces);
      } catch (_) {
        cf = null;
      }
    }
    return AnalysisResult(
      githubUsername: github,
      leetcodeUsername: leetcode,
      codeforcesHandle: codeforces,
      github: gh,
      leetcode: lc,
      codeforces: cf,
      contributions: contrib,
      analyzedAt: DateTime.now(),
    );
  }
}
