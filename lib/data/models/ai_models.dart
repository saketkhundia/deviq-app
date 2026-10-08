import 'github_models.dart';

/// Structured AI code review (POST /ai/review).
class ReviewIssue {
  const ReviewIssue(
      {required this.severity, required this.title, required this.detail});
  final String severity; // bug | warning | security
  final String title;
  final String detail;
}

class CodeReviewResult {
  const CodeReviewResult({
    required this.summary,
    required this.score,
    required this.bugs,
    required this.warnings,
    required this.security,
    required this.suggestions,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.fixedCode,
    required this.raw,
  });

  final String summary;
  final double score;
  final List<ReviewIssue> bugs;
  final List<ReviewIssue> warnings;
  final List<ReviewIssue> security;
  final List<String> suggestions;
  final String timeComplexity;
  final String spaceComplexity;
  final String fixedCode;
  final Map<String, dynamic> raw;

  static List<ReviewIssue> _issues(dynamic v, String fallback) => asList(v)
      .map((e) => e is Map<String, dynamic>
          ? ReviewIssue(
              severity: fallback,
              title: parseString(e['title'] ?? e['issue']),
              detail: parseString(e['detail'] ?? e['description'] ?? e['fix']))
          : ReviewIssue(severity: fallback, title: e.toString(), detail: ''))
      .toList();

  factory CodeReviewResult.fromJson(Map<String, dynamic> j) {
    final bugs = _issues(j['bugs'], 'bug');
    final warnings = _issues(j['warnings'], 'warning');
    final security = _issues(
        j['security_issues'] ?? j['security'], 'security');
    return CodeReviewResult(
      summary: parseString(j['summary']),
      score: parseDouble(j['score'] ?? j['quality_score']),
      bugs: const [],
      warnings: const [],
      security: const [],
      suggestions: asList(j['suggestions'] ?? j['improvements'])
          .map((e) => e.toString())
          .toList(),
      timeComplexity: parseString(j['time_complexity']),
      spaceComplexity: parseString(j['space_complexity']),
      fixedCode: parseString(j['fixed_code'] ?? j['optimized_code']),
      raw: j,
    )._withIssues(bugs, warnings, security);
  }

  CodeReviewResult _withIssues(List<ReviewIssue> b, List<ReviewIssue> w,
          List<ReviewIssue> s) =>
      CodeReviewResult(
        summary: summary,
        score: score,
        bugs: b,
        warnings: w,
        security: s,
        suggestions: suggestions,
        timeComplexity: timeComplexity,
        spaceComplexity: spaceComplexity,
        fixedCode: fixedCode,
        raw: raw,
      );

  List<ReviewIssue> get issues => [...bugs, ...warnings, ...security];
}

/// Chat message for AI assistant.
class ChatMessage {
  ChatMessage({
    required this.role, // user | assistant
    required this.content,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final String role;
  final String content;
  final DateTime at;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// LeetCode company problem (GET /leetcode/company-problems/{slug}).
class CompanyProblem {
  const CompanyProblem({
    required this.slug,
    required this.title,
    required this.difficulty,
    required this.url,
    required this.paidOnly,
  });

  final String slug;
  final String title;
  final String difficulty;
  final String url;
  final bool paidOnly;

  factory CompanyProblem.fromJson(Map<String, dynamic> j) => CompanyProblem(
        slug: parseString(j['slug']),
        title: parseString(j['title']),
        difficulty: parseString(j['difficulty']),
        url: parseString(j['url']),
        paidOnly: j['paidOnly'] == true,
      );
}

/// Code execution result (POST /execute, or /exec/start + /exec/poll).
class ExecutionResult {
  const ExecutionResult({
    required this.output,
    required this.error,
    required this.exitCode,
    required this.elapsedMs,
    required this.timedOut,
  });

  final String output;
  final String error;
  final int exitCode;
  final int elapsedMs;
  final bool timedOut;

  bool get success => exitCode == 0 && !timedOut;

  factory ExecutionResult.fromJson(Map<String, dynamic> j) =>
      ExecutionResult(
        output: parseString(j['output'] ?? j['stdout']),
        error: parseString(j['error'] ?? j['stderr']),
        exitCode: parseInt(j['exit_code'] ?? j['exitCode']),
        elapsedMs: parseInt(j['elapsed_ms'] ?? j['elapsedMs'] ?? j['time_ms']),
        timedOut: j['timed_out'] == true || j['timedOut'] == true,
      );
}
