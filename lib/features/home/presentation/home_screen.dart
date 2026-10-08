import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';

/// Home: hero + primary actions + feature grid + product info.
/// Mobile adaptation of the web landing hierarchy.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DevIQPage(
      reserveNav: true,
      children: [
        const DevIQSectionLabel('DEVELOPER ANALYTICS PLATFORM'),
        const SizedBox(height: 12),
        Text(
          'Your developer\nprofile, fully\nmeasured.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.04,
            letterSpacing: -0.02,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DevIQ unifies your GitHub, LeetCode, and Codeforces stats into a single score — with AI insights, contribution tracking, and head-to-head comparisons.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        DevIQButton(
          label: 'Analyze Profile',
          icon: Icons.analytics_outlined,
          onPressed: () => context.go('/analyze'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DevIQSecondaryButton(
                label: 'Try Playground',
                icon: Icons.terminal,
                onPressed: () => context.go('/playground'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DevIQSecondaryButton(
                label: 'Compare',
                icon: Icons.compare_arrows,
                onPressed: () => context.go('/compare'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const DevIQSectionLabel('PLATFORM'),
        const SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.hub_outlined,
          iconColor: DevIQColors.github,
          title: 'GitHub Analytics',
          description:
              'Repos, stars, languages, streaks and contribution heatmaps.',
          route: '/analyze',
        ),
        _FeatureCard(
          icon: Icons.code_outlined,
          iconColor: DevIQColors.leetcode,
          title: 'LeetCode Stats',
          description: 'Problems solved, difficulty split, ranking and rating.',
          route: '/analyze',
        ),
        _FeatureCard(
          icon: Icons.emoji_events_outlined,
          iconColor: DevIQColors.codeforces,
          title: 'Codeforces Rating',
          description:
              'Rating, rank progression, contests and problems solved.',
          route: '/analyze',
        ),
        _FeatureCard(
          icon: Icons.donut_small_outlined,
          iconColor: DevIQColors.success,
          title: 'Unified Score',
          description: 'One weighted DevIQ score across all three platforms.',
          route: '/analyze',
        ),
        _FeatureCard(
          icon: Icons.auto_awesome_outlined,
          iconColor: DevIQColors.ai,
          title: 'AI Insights',
          description: 'Personalized coaching from your real analysis history.',
          route: '/ai',
        ),
        _FeatureCard(
          icon: Icons.compare_arrows_outlined,
          iconColor: DevIQColors.teal,
          title: 'Compare Mode',
          description: 'Head-to-head developer comparison, metric by metric.',
          route: '/compare',
        ),
        _FeatureCard(
          icon: Icons.terminal_outlined,
          iconColor: null,
          title: 'Code Playground',
          description:
              'Write, run and test code in 11 languages with a terminal.',
          route: '/playground',
        ),
        _FeatureCard(
          icon: Icons.rate_review_outlined,
          iconColor: DevIQColors.codeforces,
          title: 'AI Code Review',
          description:
              'Senior-level reviews: bugs, security, complexity, fixes.',
          route: '/review',
        ),
        const SizedBox(height: 28),
        DevIQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to measure\nyour profile?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect your usernames and get a unified score in seconds.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              DevIQButton(
                label: 'Get Started',
                icon: Icons.arrow_forward,
                onPressed: () => context.go('/analyze'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const DevIQSectionLabel('WHAT IS DEVIQ?'),
        const SizedBox(height: 8),
        Text(
          'DevIQ is a developer intelligence platform. It pulls your public footprint from GitHub, LeetCode and Codeforces, normalizes each signal into a 0–100 platform score, and blends them into one unified DevIQ score — with AI that explains what to improve next.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        const DevIQSectionLabel('HOW IT WORKS'),
        const SizedBox(height: 12),
        const _Step(
          n: '01',
          title: 'Connect',
          body: 'Enter your GitHub, LeetCode and Codeforces handles.',
        ),
        const _Step(
          n: '02',
          title: 'Analyze',
          body: 'DevIQ fetches live data and computes per-platform scores.',
        ),
        const _Step(
          n: '03',
          title: 'Improve',
          body: 'Follow AI insights, prep interviews and track history.',
        ),
        const SizedBox(height: 20),
        const DevIQSectionLabel('SUPPORTED PLATFORMS'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Platform',
                value: 'GitHub',
                accent: DevIQColors.github,
                sub: 'Repos · Stars · Streaks',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Platform',
                value: 'LeetCode',
                accent: DevIQColors.leetcode,
                sub: 'Solved · Ranking',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Platform',
                value: 'Codeforces',
                accent: DevIQColors.codeforces,
                sub: 'Rating · Rank',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DevIQCard(
        onTap: () {
          if (route == '/analyze' ||
              route == '/compare' ||
              route == '/playground') {
            context.go(route);
          } else {
            context.push(route);
          }
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.onSurface).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (iconColor ?? theme.dividerColor).withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Icon(
                icon,
                size: 19,
                color: iconColor ?? theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.body});
  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
