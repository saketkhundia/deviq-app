import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/deviq_widgets.dart';

/// Hero: eyebrow, heading, supporting copy and the three CTAs.
/// Buttons stack gracefully on narrow phones instead of clipping.
class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DevIQSectionLabel('DEVELOPER ANALYTICS PLATFORM'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final size = w < 380 ? 36.0 : (w < 600 ? 40.0 : 52.0);
            return Text(
              'Your developer\nprofile,\nfully measured.',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.04,
                letterSpacing: -0.02,
                fontSize: size,
              ),
            );
          },
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
        LayoutBuilder(
          builder: (context, c) {
            final secondary = [
              DevIQSecondaryButton(
                label: 'Try Playground',
                icon: Icons.terminal,
                onPressed: () => context.push('/playground'),
              ),
              DevIQSecondaryButton(
                label: 'Compare Developers',
                icon: Icons.compare_arrows,
                onPressed: () => context.push('/compare'),
              ),
            ];
            // Side-by-side only when both labels comfortably fit;
            // otherwise stack full-width so nothing clips.
            if (c.maxWidth >= 340) {
              return Row(
                children: [
                  for (var i = 0; i < secondary.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 5,
                          right: i == 0 ? 5 : 0,
                        ),
                        child: secondary[i],
                      ),
                    ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                secondary[0],
                const SizedBox(height: 10),
                secondary[1],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Thin horizontal divider between major home sections.
class HomeDivider extends StatelessWidget {
  const HomeDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Divider(height: 1, thickness: 1),
  );
}
