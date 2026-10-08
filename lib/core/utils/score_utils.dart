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
    if (score >= 85) return 'Exceptional';
    if (score >= 70) return 'Strong';
    if (score >= 55) return 'Solid';
    if (score >= 40) return 'Developing';
    if (score > 0) return 'Getting started';
    return 'No data';
  }

  /// Heuristic GitHub score from repo/stars/language signals (0–100).
  static double githubScore(
      {required int repos, required int stars, required int languages}) {
    var s = 0.0;
    s += (repos / 30 * 35).clamp(0, 35);
    s += (stars / 500 * 45).clamp(0, 45);
    s += (languages / 8 * 20).clamp(0, 20);
    return s.clamp(0, 100);
  }

  /// Heuristic LeetCode score from solved + rating mix (0–100).
  static double leetcodeScore(
      {required int solved,
      required int hard,
      int? rating,
      int? ranking}) {
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
  static double codeforcesScore(
      {int? rating, int? contests, int? solved}) {
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
}
