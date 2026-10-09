import 'package:deviq/core/theme/deviq_colors.dart';
import 'package:deviq/core/utils/score_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScoreUtils.unified', () {
    test('weights github/leetcode/codeforces', () {
      expect(
        ScoreUtils.unified(github: 100, leetcode: 100, codeforces: 100),
        closeTo(100, 0.001),
      );
      expect(ScoreUtils.unified(github: 80), closeTo(80, 0.001));
      expect(ScoreUtils.unified(), 0);
    });

    test('ignores missing platforms', () {
      expect(ScoreUtils.unified(github: 60, leetcode: 40), closeTo(51.4, 0.2));
    });
  });

  group('ScoreUtils.verdict', () {
    test('bands match the web reference', () {
      expect(ScoreUtils.verdict(100), 'Elite');
      expect(ScoreUtils.verdict(70), 'Senior');
      expect(ScoreUtils.verdict(50), 'Mid-Level');
      expect(ScoreUtils.verdict(40), 'Junior');
      expect(ScoreUtils.verdict(13), 'Beginner');
      expect(ScoreUtils.verdict(0), 'No data');
    });
  });

  group('score colors', () {
    test('thresholds match web design', () {
      expect(DevIQColors.scoreColor(85), DevIQColors.success);
      expect(DevIQColors.scoreColor(65), DevIQColors.github);
      expect(DevIQColors.scoreColor(45), DevIQColors.leetcode);
      expect(ScoreUtils.githubScore(repos: 0, stars: 0, languages: 0), 0);
      expect(DevIQColors.scoreColor(10), DevIQColors.error);
    });
  });

  group('heuristics stay in range', () {
    test('github/leetcode/codeforces clamp 0..100', () {
      expect(
        ScoreUtils.githubScore(repos: 500, stars: 999999, languages: 40),
        100,
      );
      expect(
        ScoreUtils.leetcodeScore(solved: 3000, hard: 999, rating: 3500),
        100,
      );
      expect(
        ScoreUtils.codeforcesScore(rating: 4000, contests: 500, solved: 5000),
        100,
      );
    });
  });

  group('Validators', () {
    test('username/email/password', () {
      expect(Validators.username('', required: false), isNull);
      expect(Validators.username('', required: true), isNotNull);
      expect(Validators.username('a'), isNotNull);
      expect(Validators.username('tourist-123'), isNull);
      expect(Validators.email('x@y.z'), isNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.password('short', isSignup: true), isNotNull);
      expect(Validators.password('long-enough', isSignup: true), isNull);
    });
  });

  group('Codeforces rank colors', () {
    test('ranks map to accents', () {
      expect(
        DevIQColors.cfRankColor('legendary grandmaster'),
        DevIQColors.error,
      );
      expect(DevIQColors.cfRankColor('master'), DevIQColors.warning);
      expect(
        DevIQColors.cfRankColor('candidate master'),
        DevIQColors.codeforces,
      );
      expect(DevIQColors.cfRankColor('expert'), DevIQColors.github);
      expect(DevIQColors.cfRankColor('specialist'), DevIQColors.teal);
      expect(DevIQColors.cfRankColor('pupil'), DevIQColors.success);
    });
  });
}
