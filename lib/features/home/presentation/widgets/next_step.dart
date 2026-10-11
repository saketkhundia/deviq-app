import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/score_utils.dart';
import '../../../../core/utils/weak_categories.dart';
import '../../../../data/models/analysis_models.dart';
import 'liquid_glass.dart';

/// 04 / Next step — rebuilt from scratch in liquid glass: one frosted
/// directive panel with a luminous icon lens and a ghost-glass action.
///
/// The directive itself is derived from real data only. Every
/// recommendation routes to an existing, backend-supported
/// destination: re-analysis, interview drills (local topic estimates
/// from LeetCode totals), the AI 7-day plan endpoint, code review,
/// or comparison. Nothing is suggested that the app cannot do.
class NextStepSection extends StatelessWidget {
  const NextStepSection({
    super.key,
    required this.result,
    required this.last,
    required this.failedPlatforms,
  });

  final AnalysisResult? result;
  final HistoryRecord? last;
  final List<String> failedPlatforms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final directive = deriveNextStep(
      result: result,
      last: last,
      failedPlatforms: failedPlatforms,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlassSectionHeader(
          index: '04',
          title: 'Next step',
        ),
        const SizedBox(height: 14),
        LiquidGlass(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: dark
                        ? [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.05),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                          ],
                  ),
                  border: Border.all(
                    color: LiquidGlassTokens.edge(dark),
                  ),
                ),
                child: Icon(
                  directive.icon,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      directive.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      directive.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassGhostButton(
                      label: directive.action,
                      icon: Icons.arrow_forward,
                      onTap: () => context.push(directive.route),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single derived directive. Pure — unit tested.
class NextDirective {
  const NextDirective({
    required this.title,
    required this.detail,
    required this.action,
    required this.route,
    required this.icon,
  });

  final String title;
  final String detail;
  final String action;
  final String route;
  final IconData icon;
}

NextDirective deriveNextStep({
  required AnalysisResult? result,
  required HistoryRecord? last,
  required List<String> failedPlatforms,
}) {
  // 1. Nothing ever analyzed → onboard.
  if (result == null && last == null) {
    return const NextDirective(
      title: 'Analyze your developer profile',
      detail:
          'Enter one username — GitHub, LeetCode or Codeforces — and get a unified score with breakdowns in seconds.',
      action: 'Start analysis',
      route: '/analyze',
      icon: Icons.analytics_outlined,
    );
  }

  // 2. A platform was requested but unreachable → retry it.
  if (failedPlatforms.isNotEmpty) {
    final names = failedPlatforms.join(', ');
    return NextDirective(
      title: 'Retry $names',
      detail:
          '$names couldn\u2019t be reached during the last run. Re-run the analysis to complete your unified score.',
      action: 'Re-run analysis',
      route: '/analyze',
      icon: Icons.refresh,
    );
  }

  // 3. History only → refresh for live data.
  if (result == null) {
    return NextDirective(
      title: 'Refresh your profile',
      detail:
          'Your last analysis is ${Formatters.date(last!.date)}. Re-run it to update your score, streaks and skill profile.',
      action: 'Re-run analysis',
      route: '/analyze',
      icon: Icons.refresh,
    );
  }

  // 4. An expected platform is missing → connect it.
  if (result.github == null) {
    return const NextDirective(
      title: 'Connect GitHub',
      detail:
          'Repository activity carries the largest weight in your unified score. Add your GitHub username to unlock it.',
      action: 'Connect GitHub',
      route: '/analyze',
      icon: Icons.code_outlined,
    );
  }
  if (result.leetcode == null) {
    return const NextDirective(
      title: 'Connect LeetCode',
      detail:
          'Problem-solving volume is missing from your profile. Add your LeetCode username to sharpen the picture.',
      action: 'Connect LeetCode',
      route: '/analyze',
      icon: Icons.code_outlined,
    );
  }
  if (result.codeforces == null) {
    return const NextDirective(
      title: 'Connect Codeforces',
      detail:
          'Contest rating is the smallest but sharpest signal. Add your handle to complete the competitive axis.',
      action: 'Connect Codeforces',
      route: '/analyze',
      icon: Icons.code_outlined,
    );
  }

  // 5. All connected → address the weakest axis.
  final scores = <String, double>{
    'github': result.githubScore ?? 0,
    'leetcode': result.leetcodeScore ?? 0,
    'codeforces': result.codeforcesScore ?? 0,
  };
  final weakest =
      scores.entries.reduce((a, b) => a.value <= b.value ? a : b).key;

  switch (weakest) {
    case 'leetcode':
      final lc = result.leetcode!;
      final weak = estimateWeakCategories(
        easySolved: lc.easySolved,
        mediumSolved: lc.mediumSolved,
        hardSolved: lc.hardSolved,
      ).firstOrNull;
      final topic = weak == null ? 'core topics' : weak.name;
      return NextDirective(
        title: 'Drill $topic',
        detail:
            'Problem solving trails your other axes at ${scores['leetcode']!.toStringAsFixed(0)}. Interview Prep targets $topic first — your weakest estimated category.',
        action: 'Start drills',
        route: '/interview',
        icon: Icons.track_changes_outlined,
      );
    case 'codeforces':
      return NextDirective(
        title: 'Follow a 7-day improvement plan',
        detail:
            'Competitive programming is your lowest axis at ${scores['codeforces']!.toStringAsFixed(0)}. Ask AI for a focused daily plan built on your weak areas.',
        action: 'Get my plan',
        route: '/ai',
        icon: Icons.auto_awesome_outlined,
      );
    default:
      final repos = List.of(result.github!.repositories)
        ..sort((a, b) => b.stars.compareTo(a.stars));
      final top = repos.firstOrNull;
      return NextDirective(
        title: top == null
            ? 'Review your code with AI'
            : 'Review ${top.name}',
        detail: top == null
            ? 'Engineering activity trails at ${scores['github']!.toStringAsFixed(0)}. Paste a recent file into AI Review for concrete fixes.'
            : 'Engineering activity trails at ${scores['github']!.toStringAsFixed(0)}. Paste ${top.name} (${top.stars}★) into AI Review for bugs, complexity and fixes.',
        action: 'Open AI Review',
        route: '/review',
        icon: Icons.rate_review_outlined,
      );
  }
}
