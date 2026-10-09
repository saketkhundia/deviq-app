import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../shared/widgets/deviq_widgets.dart';
import '../../../../shared/widgets/platform_icons.dart';

/// Single feature entry: outlined icon tile, semibold title, muted copy.
/// Taps route to the matching existing destination.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
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

  static bool _isTab(String route) =>
      route == '/home' ||
      route == '/analyze' ||
      route == '/interview' ||
      route == '/ai';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: const EdgeInsets.all(18),
      onTap: () {
        if (_isTab(route)) {
          context.go(route);
        } else {
          context.push(route);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: (iconColor ?? theme.dividerColor).withValues(alpha: 0.3),
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
                const SizedBox(height: 4),
                Text(
                  description,
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

/// Responsive feature grid: 3 columns on desktop, 2 on tablet/wide,
/// 1 column on phones. Bounded — grids never scroll independently.
class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key, required this.cards});

  final List<FeatureCard> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth;
      final cols = w > 1024 ? 3 : (w >= 600 ? 2 : 1);
      if (cols == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == cards.length - 1 ? 0 : 10,
                ),
                child: cards[i],
              ),
          ],
        );
      }
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 118,
        ),
        itemCount: cards.length,
        itemBuilder: (context, i) => cards[i],
      );
    },
  );
}

/// The eight product features, in reference order with reference copy.
List<FeatureCard> buildFeatureCards() => [
  FeatureCard(
    icon: PlatformIcons.of(DevPlatform.github),
    iconColor: DevIQColors.github,
    title: 'GitHub Analytics',
    description: 'Repos, stars, language breakdown, skill score, and contribution heatmap.',
    route: '/analyze',
  ),
  FeatureCard(
    icon: PlatformIcons.of(DevPlatform.leetcode),
    iconColor: DevIQColors.leetcode,
    title: 'LeetCode Stats',
    description: 'Problems solved across Easy, Medium, and Hard. Contest ratings and global rank.',
    route: '/analyze',
  ),
  FeatureCard(
    icon: PlatformIcons.of(DevPlatform.codeforces),
    iconColor: DevIQColors.codeforces,
    title: 'Codeforces Rating',
    description: 'Current and peak ratings, rank titles, problems solved, and contest history.',
    route: '/analyze',
  ),
  FeatureCard(
    icon: Icons.track_changes_outlined,
    iconColor: DevIQColors.success,
    title: 'Unified Score',
    description: 'A single weighted developer score combining activity, problem solving, and competitive programming.',
    route: '/analyze',
  ),
  FeatureCard(
    icon: Icons.grid_view_outlined,
    iconColor: DevIQColors.ai,
    title: 'AI Insights',
    description: 'Get an AI-generated analysis or a personalized seven-day improvement plan.',
    route: '/ai',
  ),
  FeatureCard(
    icon: Icons.compare_arrows_outlined,
    iconColor: DevIQColors.teal,
    title: 'Compare Mode',
    description:
        'Head-to-head comparison between two developers across every metric.',
    route: '/compare',
  ),
  FeatureCard(
    icon: Icons.play_arrow_rounded,
    title: 'Code Playground',
    description: 'Write and run JavaScript, Python, Java, Go, Rust, and more, with live output.',
    route: '/playground',
  ),
  FeatureCard(
    icon: Icons.check_rounded,
    iconColor: DevIQColors.codeforces,
    title: 'AI Code Review',
    description: 'Paste code for bugs, time and space complexity, security issues, and fixes.',
    route: '/review',
  ),
];
