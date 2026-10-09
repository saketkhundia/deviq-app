import '../../data/models/analysis_models.dart';
import '../../data/models/github_models.dart';

/// Deterministic developer role-fit estimation computed transparently from
/// the user's REAL public signals (languages, repo counts, LeetCode
/// volume, Codeforces rating, stars). The backend exposes no role
/// endpoint — the web client derives the same way — so percentages here
/// are client-side estimates; the UI labels them as such and never
/// presents them as server scores.
class RoleFit {
  const RoleFit({
    required this.role,
    required this.percent,
    this.evidence = const [],
  });

  final String role;

  /// Best match normalized to 100.
  final double percent;

  /// Human-readable signal proofs, e.g. "65% mobile languages".
  final List<String> evidence;
}

/// Language → role affinity weights. Keys are lowercase language names.
const Map<String, Map<String, double>> _langRoles = {
  'swift': {'Mobile Developer': 3},
  'kotlin': {'Mobile Developer': 3, 'Backend Developer': 1},
  'dart': {'Mobile Developer': 3, 'Frontend Developer': 1},
  'objective-c': {'Mobile Developer': 3},
  'javascript': {'Frontend Developer': 3, 'Full-Stack Developer': 1.5},
  'typescript': {
    'Frontend Developer': 3,
    'Full-Stack Developer': 1.5,
    'Backend Developer': 1,
  },
  'html': {'Frontend Developer': 3},
  'css': {'Frontend Developer': 3},
  'vue': {'Frontend Developer': 2.5},
  'svelte': {'Frontend Developer': 2.5},
  'python': {
    'Backend Developer': 2,
    'ML/Data Engineer': 2.5,
    'Security Engineer': 1,
  },
  'java': {
    'Backend Developer': 2.5,
    'Application Developer': 1.5,
    'Competitive Programmer': 1,
  },
  'go': {'Backend Developer': 2.5, 'Security Engineer': 0.5},
  'rust': {
    'Backend Developer': 1.5,
    'Security Engineer': 2,
    'Embedded/IoT Developer': 2,
  },
  'c#': {'Backend Developer': 1.5, 'Application Developer': 1},
  'c++': {
    'Competitive Programmer': 2.5,
    'Embedded/IoT Developer': 1.5,
    'Security Engineer': 1,
    'Application Developer': 0.5,
  },
  'c': {
    'Embedded/IoT Developer': 3,
    'Security Engineer': 1.5,
    'Application Developer': 0.5,
  },
  'php': {'Backend Developer': 2},
  'ruby': {'Backend Developer': 2, 'Application Developer': 0.5},
  'scala': {'Backend Developer': 1.5, 'ML/Data Engineer': 1},
  'jupyter notebook': {'ML/Data Engineer': 3},
  'r': {'ML/Data Engineer': 2.5},
  'julia': {'ML/Data Engineer': 2},
  'shell': {'Security Engineer': 1.5, 'Application Developer': 0.5},
  'assembly': {'Security Engineer': 2, 'Embedded/IoT Developer': 2},
  'arduino': {'Embedded/IoT Developer': 3},
};

/// Canonical web role order.
const List<String> roleOrder = [
  'Mobile Developer',
  'Competitive Programmer',
  'Backend Developer',
  'Application Developer',
  'ML/Data Engineer',
  'Full-Stack Developer',
  'Frontend Developer',
  'Security Engineer',
  'Embedded/IoT Developer',
];

const _mobileLangs = {'swift', 'kotlin', 'dart', 'objective-c'};
const _frontendLangs = {
  'javascript',
  'typescript',
  'html',
  'css',
  'vue',
  'svelte',
  'dart',
};
const _backendLangs = {
  'python',
  'java',
  'go',
  'rust',
  'c#',
  'php',
  'ruby',
  'scala',
  'kotlin',
  'typescript',
};
const _systemsLangs = {'c', 'c++', 'rust', 'assembly', 'arduino', 'shell'};

/// Returns role fits sorted best-first with 0–100 normalized percents.
List<RoleFit> estimateRoleFit(AnalysisResult r) {
  final scores = <String, double>{for (final role in roleOrder) role: 0};

  void add(String role, double v) {
    scores[role] = (scores[role] ?? 0) + v;
  }

  // 1. Language distribution.
  final langs = r.github?.languageDistribution ?? const {};
  var langTotal = 0;
  langs.forEach((_, v) => langTotal += v);
  langs.forEach((lang, count) {
    final roles = _langRoles[lang.toLowerCase()];
    if (roles == null) {
      add('Application Developer', count * 0.6);
      return;
    }
    roles.forEach((role, w) => add(role, count * w));
  });
  final breadth = langs.length;
  if (breadth >= 4) add('Full-Stack Developer', breadth * 1.2);
  if (breadth >= 2) add('Application Developer', breadth * 0.8);

  // 2. LeetCode volume → algorithmic roles.
  final lc = r.leetcode;
  if (lc != null && lc.totalSolved > 0) {
    add('Competitive Programmer', lc.hardSolved * 1.4 + lc.mediumSolved * 0.5);
    add('Backend Developer', lc.mediumSolved * 0.3 + lc.hardSolved * 0.5);
    add('ML/Data Engineer', lc.mediumSolved * 0.2);
  }

  // 3. Codeforces rating → competitive weight.
  final cf = r.codeforces;
  if (cf != null && cf.rating > 0) {
    add('Competitive Programmer', (cf.rating - 800) / 60);
    if (cf.contestsParticipated > 10) {
      add('Competitive Programmer', cf.contestsParticipated * 0.4);
    }
  }

  // 4. OSS traction → product-oriented roles.
  final stars = r.github?.totalStars ?? 0;
  if (stars > 0) {
    add('Full-Stack Developer', ((stars / 40).clamp(0, 12)).toDouble());
    add('Application Developer', ((stars / 60).clamp(0, 8)).toDouble());
  }

  final maxScore = scores.values.fold<double>(0, (a, b) => a > b ? a : b);
  if (maxScore <= 0) return const [];
  final order = List<String>.from(roleOrder)
    ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
  return [
    for (final role in order)
      if (scores[role]! / maxScore * 100 > 0.5)
        RoleFit(
          role: role,
          percent: scores[role]! / maxScore * 100,
          evidence: roleEvidence(role, r),
        ),
  ];
}

int _repoLangCount(AnalysisResult r, Set<String> langs) {
  var n = 0;
  for (final repo in r.github?.repositories ?? const <GithubRepo>[]) {
    if (langs.contains(repo.language.toLowerCase())) n++;
  }
  return n;
}

int _langWeightTotal(AnalysisResult r) {
  var n = 0;
  r.github?.languageDistribution.forEach((_, v) => n += v);
  return n;
}

int _langWeightIn(AnalysisResult r, Set<String> langs) {
  var n = 0;
  r.github?.languageDistribution.forEach((lang, count) {
    if (langs.contains(lang.toLowerCase())) n += count;
  });
  return n;
}

/// Real-number evidence strings backing each role's percentage.
List<String> roleEvidence(String role, AnalysisResult r) {
  final out = <String>[];
  void add(String s) {
    if (out.length < 2) out.add(s);
  }

  final total = _langWeightTotal(r);
  switch (role) {
    case 'Mobile Developer':
      final n = _repoLangCount(r, _mobileLangs);
      final share = total == 0
          ? 0
          : (_langWeightIn(r, _mobileLangs) / total * 100).round();
      if (share > 0) add('$share% mobile languages');
      if (n > 0) add('$n mobile repo${n == 1 ? '' : 's'}');
    case 'Competitive Programmer':
      final cf = r.codeforces;
      if (cf != null && cf.rating > 0) add('CF ${cf.rating}');
      final hard = r.leetcode?.hardSolved ?? 0;
      if (hard > 0) add('$hard hard solved');
    case 'Backend Developer':
      final n = _repoLangCount(r, _backendLangs);
      if (n > 0) add('$n backend repo${n == 1 ? '' : 's'}');
      final med = (r.leetcode?.mediumSolved ?? 0);
      if (med > 0) add('$med LC medium');
    case 'Application Developer':
      final repos = r.github?.totalProjects ?? 0;
      if (repos > 0) add('$repos repos');
      final stars = r.github?.totalStars ?? 0;
      if (stars > 0) add('$stars stars');
    case 'ML/Data Engineer':
      final n = _langWeightIn(r, {'python', 'jupyter notebook', 'r', 'julia'});
      if (n > 0) add('Python ×$n');
      final solved = r.leetcode?.totalSolved ?? 0;
      if (solved > 0) add('$solved LC solved');
    case 'Full-Stack Developer':
      final langs = r.github?.languageDistribution.length ?? 0;
      if (langs >= 2) add('$langs languages');
      final stars = r.github?.totalStars ?? 0;
      if (stars > 0) add('$stars stars');
    case 'Frontend Developer':
      final share = total == 0
          ? 0
          : (_langWeightIn(r, _frontendLangs) / total * 100).round();
      if (share > 0) add('$share% frontend');
      final n = _repoLangCount(r, _frontendLangs);
      if (n > 0) add('$n frontend repo${n == 1 ? '' : 's'}');
    case 'Security Engineer':
      final n = _repoLangCount(r, _systemsLangs);
      if (n > 0) add('$n systems repo${n == 1 ? '' : 's'}');
      final issues = (r.github?.repositories ?? const <GithubRepo>[]).fold<int>(
        0,
        (a, e) => a + e.openIssues,
      );
      if (issues > 0) add('$issues open issues');
    case 'Embedded/IoT Developer':
      final n = _langWeightIn(r, {'c', 'c++', 'rust', 'assembly', 'arduino'});
      if (n > 0) add('C/C++ ×$n');
      final repos = _repoLangCount(r, {
        'c',
        'c++',
        'rust',
        'assembly',
        'arduino',
      });
      if (repos > 0) add('$repos embedded repo${repos == 1 ? '' : 's'}');
  }
  return out;
}
