import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../shared/widgets/platform_icons.dart';
import 'liquid_glass.dart';

/// Feature catalog data. Rendering lives in [FeatureList].
class FeatureEntry {
  const FeatureEntry({
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

  void open(BuildContext context) {
    if (_isTab(route)) {
      context.go(route);
    } else {
      context.push(route);
    }
  }
}

/// Tools index rebuilt from scratch in liquid glass: one frosted
/// panel, hairline-separated rows, luminous icon lenses. Platform
/// colors appear only on the three platform rows, where color carries
/// meaning; everything else stays monochrome.
class FeatureList extends StatelessWidget {
  const FeatureList({super.key, required this.entries});

  final List<FeatureEntry> entries;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlass(
      padding: EdgeInsets.zero,
      blur: 16,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _FeatureRow(entry: entries[i]),
            if (i != entries.length - 1)
              Divider(
                height: 1,
                indent: 58,
                color: LiquidGlassTokens.edge(dark),
              ),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.entry});

  final FeatureEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = entry.iconColor ?? theme.colorScheme.secondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => entry.open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          Colors.white.withValues(alpha: 0.13),
                          Colors.white.withValues(alpha: 0.04),
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
              child: Icon(entry.icon, size: 16, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.chevron_right,
                size: 15,
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The eight product features, in reference order with reference copy.
List<FeatureEntry> buildFeatureCards() => [
  FeatureEntry(
    icon: PlatformIcons.of(DevPlatform.github),
    iconColor: DevIQColors.github,
    title: 'GitHub Analytics',
    description: 'Repos, stars, language breakdown, skill score, and contribution heatmap.',
    route: '/analyze',
  ),
  FeatureEntry(
    icon: PlatformIcons.of(DevPlatform.leetcode),
    iconColor: DevIQColors.leetcode,
    title: 'LeetCode Stats',
    description: 'Problems solved across Easy, Medium, and Hard. Contest ratings and global rank.',
    route: '/analyze',
  ),
  FeatureEntry(
    icon: PlatformIcons.of(DevPlatform.codeforces),
    iconColor: DevIQColors.codeforces,
    title: 'Codeforces Rating',
    description: 'Current and peak ratings, rank titles, problems solved, and contest history.',
    route: '/analyze',
  ),
  const FeatureEntry(
    icon: Icons.track_changes_outlined,
    title: 'Unified Score',
    description: 'A single weighted developer score combining activity, problem solving, and competitive programming.',
    route: '/analyze',
  ),
  const FeatureEntry(
    icon: Icons.grid_view_outlined,
    title: 'AI Insights',
    description: 'Get an AI-generated analysis or a personalized seven-day improvement plan.',
    route: '/ai',
  ),
  const FeatureEntry(
    icon: Icons.compare_arrows_outlined,
    title: 'Compare Mode',
    description:
        'Head-to-head comparison between two developers across every metric.',
    route: '/compare',
  ),
  const FeatureEntry(
    icon: Icons.play_arrow_rounded,
    title: 'Code Playground',
    description: 'Write and run JavaScript, Python, Java, Go, Rust, and more, with live output.',
    route: '/playground',
  ),
  const FeatureEntry(
    icon: Icons.check_rounded,
    title: 'AI Code Review',
    description: 'Paste code for bugs, time and space complexity, security issues, and fixes.',
    route: '/review',
  ),
];
