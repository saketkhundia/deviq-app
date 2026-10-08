int _i(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _d(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String _s(dynamic v) => v?.toString() ?? '';

/// Shared defensive JSON helpers.
Map<String, dynamic> asMap(dynamic v) =>
    v is Map<String, dynamic> ? v : <String, dynamic>{};
List<dynamic> asList(dynamic v) => v is List ? v : const [];

int parseInt(dynamic v) => _i(v);
double parseDouble(dynamic v) => _d(v);
String parseString(dynamic v) => _s(v);

/// GitHub repository (subset of the GitHub REST shape returned by /analyze).
class GithubRepo {
  const GithubRepo({
    required this.name,
    required this.fullName,
    required this.htmlUrl,
    required this.description,
    required this.language,
    required this.stars,
    required this.forks,
    required this.topics,
    required this.updatedAt,
    required this.isPrivate,
    required this.isFork,
  });

  final String name;
  final String fullName;
  final String htmlUrl;
  final String description;
  final String language;
  final int stars;
  final int forks;
  final List<String> topics;
  final String updatedAt;
  final bool isPrivate;
  final bool isFork;

  factory GithubRepo.fromJson(Map<String, dynamic> j) => GithubRepo(
        name: _s(j['name']),
        fullName: _s(j['full_name']),
        htmlUrl: _s(j['html_url']),
        description: _s(j['description']),
        language: _s(j['language']),
        stars: _i(j['stargazers_count'] ?? j['stars']),
        forks: _i(j['forks_count'] ?? j['forks']),
        topics: asList(j['topics']).map((e) => e.toString()).toList(),
        updatedAt: _s(j['updated_at']),
        isPrivate: j['private'] == true,
        isFork: j['fork'] == true,
      );
}

/// Aggregated GitHub analytics from GET /analyze/{u}.
class GithubStats {
  const GithubStats({
    required this.username,
    required this.totalProjects,
    required this.totalStars,
    required this.totalForks,
    required this.skillScore,
    required this.mostUsedLanguage,
    required this.languageDistribution,
    required this.repositories,
  });

  final String username;
  final int totalProjects;
  final int totalStars;
  final int totalForks;
  final double skillScore;
  final String mostUsedLanguage;
  final Map<String, int> languageDistribution;
  final List<GithubRepo> repositories;

  factory GithubStats.fromJson(String username, Map<String, dynamic> j) {
    final a = asMap(j['analytics']);
    final repos = asList(j['repositories'])
        .whereType<Map<String, dynamic>>()
        .map(GithubRepo.fromJson)
        .toList();
    final langDist = <String, int>{};
    asMap(a['language_distribution']).forEach((k, v) {
      langDist[k] = _i(v);
    });
    var forks = 0;
    for (final r in repos) {
      forks += r.forks;
    }
    return GithubStats(
      username: username,
      totalProjects: _i(a['total_projects'] ?? repos.length),
      totalStars: _i(a['total_stars']),
      totalForks: forks,
      skillScore: _d(a['skill_score']),
      mostUsedLanguage: _s(a['most_used_language']),
      languageDistribution: langDist,
      repositories: repos,
    );
  }

  factory GithubStats.empty(String username) => GithubStats(
        username: username,
        totalProjects: 0,
        totalStars: 0,
        totalForks: 0,
        skillScore: 0,
        mostUsedLanguage: '',
        languageDistribution: const {},
        repositories: const [],
      );
}
