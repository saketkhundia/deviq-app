import 'github_models.dart';

/// Structured AI code review (POST /ai/review).
class ReviewIssue {
  const ReviewIssue({
    required this.severity,
    required this.title,
    required this.detail,
    this.line,
    this.category = '',
    this.trigger = '',
    this.expected = '',
    this.actual = '',
    this.fix = '',
    this.confidence,
  });

  final String severity; // bug | warning | security (+ backend severities)
  final String title;
  final String detail;
  final int? line;
  final String category;
  final String trigger;
  final String expected;
  final String actual;
  final String fix;
  final int? confidence;

  factory ReviewIssue.fromJson(Map<String, dynamic> j, String fallback) =>
      ReviewIssue(
        severity: parseString(j['severity']).isEmpty
            ? fallback
            : parseString(j['severity']),
        title: parseString(j['title'] ?? j['issue']),
        detail: parseString(j['detail'] ?? j['description']),
        line: j['line'] is int
            ? j['line'] as int
            : int.tryParse(parseString(j['line'])),
        category: parseString(j['category']),
        trigger: parseString(j['trigger']),
        expected: parseString(j['expected']),
        actual: parseString(j['actual']),
        fix: parseString(j['fix_explanation'] ?? j['fix']),
        confidence: j['confidence'] is int
            ? j['confidence'] as int
            : int.tryParse(parseString(j['confidence'])),
      );
}

/// Titled note ({title, detail} or plain string) for suggestions,
/// improvements and quality entries.
class ReviewNote {
  const ReviewNote({required this.title, required this.detail});

  final String title;
  final String detail;

  /// Display line: "title — detail", or whichever part exists.
  String get display {
    if (title.isEmpty) return detail;
    if (detail.isEmpty) return title;
    return '$title — $detail';
  }

  factory ReviewNote.fromJson(dynamic v) {
    if (v is Map<String, dynamic>) {
      return ReviewNote(
        title: parseString(v['title'] ?? v['category']),
        detail: parseString(v['detail'] ?? v['description']),
      );
    }
    return ReviewNote(title: '', detail: v.toString());
  }
}

/// Complexity value + explanation ({value, explanation} or plain string).
class ComplexityInfo {
  const ComplexityInfo({required this.value, required this.explanation});

  final String value;
  final String explanation;

  factory ComplexityInfo.fromJson(dynamic v) {
    if (v is Map<String, dynamic>) {
      return ComplexityInfo(
        value: parseString(v['value']),
        explanation: parseString(v['explanation'] ?? v['detail']),
      );
    }
    return ComplexityInfo(value: parseString(v), explanation: '');
  }
}

class CodeReviewResult {
  const CodeReviewResult({
    required this.summary,
    required this.score,
    required this.bugs,
    required this.warnings,
    required this.security,
    required this.suggestions,
    required this.quality,
    required this.improvements,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.fixedCode,
    required this.repairStrategy,
    required this.raw,
  });

  final String summary;
  final double score;
  final List<ReviewIssue> bugs;
  final List<ReviewIssue> warnings;
  final List<ReviewIssue> security;
  final List<ReviewNote> suggestions;
  final List<ReviewNote> quality;
  final List<ReviewNote> improvements;
  final ComplexityInfo timeComplexity;
  final ComplexityInfo spaceComplexity;
  final String fixedCode;

  /// Backend repair strategy (e.g. MINIMAL_FIX), empty when absent.
  final String repairStrategy;
  final Map<String, dynamic> raw;

  static List<ReviewIssue> _issues(dynamic v, String fallback) => asList(v)
      .map(
        (e) => e is Map<String, dynamic>
            ? ReviewIssue.fromJson(e, fallback)
            : ReviewIssue(severity: fallback, title: e.toString(), detail: ''),
      )
      .toList();

  static List<ReviewNote> _notes(dynamic v) =>
      asList(v).map(ReviewNote.fromJson).toList();

  factory CodeReviewResult.fromJson(Map<String, dynamic> j) => CodeReviewResult(
    summary: parseString(j['summary']),
    score: parseDouble(j['score'] ?? j['quality_score']),
    bugs: _issues(j['bugs'], 'bug'),
    warnings: _issues(j['warnings'], 'warning'),
    security: _issues(j['security_issues'] ?? j['security'], 'security'),
    suggestions: _notes(j['suggestions']),
    quality: _notes(j['quality']),
    improvements: _notes(j['improvements']),
    timeComplexity: ComplexityInfo.fromJson(j['time_complexity']),
    spaceComplexity: ComplexityInfo.fromJson(j['space_complexity']),
    fixedCode: parseString(j['fixed_code'] ?? j['optimized_code']),
    repairStrategy: parseString(j['repair_strategy']).replaceAll('_', ' '),
    raw: j,
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
    this.id = 0,
  });

  final String slug;
  final String title;
  final String difficulty;
  final String url;
  final bool paidOnly;

  /// LeetCode frontend question id (0 when absent).
  final int id;

  factory CompanyProblem.fromJson(Map<String, dynamic> j) => CompanyProblem(
    slug: parseString(j['slug']),
    title: parseString(j['title']),
    difficulty: parseString(j['difficulty']),
    url: parseString(j['url']),
    paidOnly: j['paidOnly'] == true,
    id: parseInt(j['id']),
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

  factory ExecutionResult.fromJson(Map<String, dynamic> j) => ExecutionResult(
    output: parseString(j['output'] ?? j['stdout']),
    error: parseString(j['error'] ?? j['stderr']),
    exitCode: parseInt(j['exit_code'] ?? j['exitCode']),
    elapsedMs: parseInt(j['elapsed_ms'] ?? j['elapsedMs'] ?? j['time_ms']),
    timedOut: j['timed_out'] == true || j['timedOut'] == true,
  );
}
