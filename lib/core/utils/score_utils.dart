import 'package:intl/intl.dart';

/// Score + verdict logic shared by analyze/compare/history.
class ScoreUtils {
  const ScoreUtils._();

  /// Weighted unified score (0–100). Weights mirror the web product:
  /// GitHub 45 / LeetCode 35 / Codeforces 20 when all present.
  static double unified({
    double? github,
    double? leetcode,
    double? codeforces,
  }) {
    double total = 0, weight = 0;
    if (github != null) {
      total += github * 0.45;
      weight += 0.45;
    }
    if (leetcode != null) {
      total += leetcode * 0.35;
      weight += 0.35;
    }
    if (codeforces != null) {
      total += codeforces * 0.20;
      weight += 0.20;
    }
    if (weight == 0) return 0;
    return (total / weight).clamp(0, 100);
  }

  static String verdict(double score) {
    // Bands reconstructed from the web reference samples
    // (100 → Elite, 40 → Junior, 13 → Beginner).
    if (score >= 85) return 'Elite';
    if (score >= 70) return 'Senior';
    if (score >= 50) return 'Mid-Level';
    if (score >= 25) return 'Junior';
    if (score > 0) return 'Beginner';
    return 'No data';
  }

  /// Heuristic GitHub score from repo/stars/language signals (0–100).
  static double githubScore({
    required int repos,
    required int stars,
    required int languages,
  }) {
    var s = 0.0;
    s += (repos / 30 * 35).clamp(0, 35);
    s += (stars / 500 * 45).clamp(0, 45);
    s += (languages / 8 * 20).clamp(0, 20);
    return s.clamp(0, 100);
  }

  /// Heuristic LeetCode score from solved + rating mix (0–100).
  static double leetcodeScore({
    required int solved,
    required int hard,
    int? rating,
    int? ranking,
  }) {
    var s = 0.0;
    s += (solved / 600 * 55).clamp(0, 55);
    s += (hard / 150 * 25).clamp(0, 25);
    if (rating != null && rating > 0) {
      s += ((rating - 1400) / 1200 * 20).clamp(0, 20);
    } else if (ranking != null && ranking > 0) {
      s += ((500000 - ranking) / 500000 * 15).clamp(0, 15);
    }
    return s.clamp(0, 100);
  }

  /// Heuristic Codeforces score from rating + activity (0–100).
  static double codeforcesScore({int? rating, int? contests, int? solved}) {
    var s = 0.0;
    if (rating != null && rating > 0) {
      s += ((rating - 800) / 2400 * 60).clamp(0, 60);
    }
    if (contests != null) s += (contests / 60 * 25).clamp(0, 25);
    if (solved != null) s += (solved / 800 * 15).clamp(0, 15);
    return s.clamp(0, 100);
  }
}

class Formatters {
  const Formatters._();
  static final _compact = NumberFormat.compact();
  static final _int = NumberFormat.decimalPattern();

  static String compact(num v) => _compact.format(v);
  static String integer(num v) => _int.format(v);
  static String date(DateTime d) => DateFormat('MMM d, yyyy').format(d);
  static String dateTime(DateTime d) =>
      DateFormat('MMM d, yyyy · h:mm a').format(d);

  /// Compact relative time matching the web client ("2y ago", "5mo ago").
  static String timeAgo(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null || iso.isEmpty) return '';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class Validators {
  const Validators._();

  static String? username(String? v, {bool required = true}) {
    if (v == null || v.trim().isEmpty) {
      return required ? 'Required' : null;
    }
    if (v.trim().length < 2) return 'Too short';
    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(v.trim())) {
      return 'Letters, numbers, _ . - only';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? v, {bool isSignup = false}) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (isSignup && v.length < 8) return 'Minimum 8 characters';
    return null;
  }

  /// Advisory password-strength score 0–4. Display-only: the backend
  /// enforces only the 8-character minimum, so this never gates signup.
  static int passwordStrength(String v) {
    var s = 0;
    if (v.length >= 8) s++;
    if (v.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) {
      s++;
    }
    if (RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      s++;
    }
    return s.clamp(0, 4);
  }

  static String passwordStrengthLabel(int s) => switch (s) {
    <= 1 => 'Weak',
    2 => 'Fair',
    3 => 'Good',
    _ => 'Strong',
  };
}
