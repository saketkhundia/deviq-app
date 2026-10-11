import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/platform_icons.dart';
import 'liquid_glass.dart';

/// Hero — what DevIQ does. Rebuilt from scratch in liquid glass:
/// luminous headline, one frosted platform strip, a signal-tinted
/// glass primary action and ghost-glass secondary paths.
class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEVELOPER INTELLIGENCE',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontSize: 11,
            color: secondary,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final size = w < 380 ? 32.0 : (w < 600 ? 34.0 : 44.0);
            return Text(
              'Your developer\nprofile, fully\nmeasured.',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.12,
                letterSpacing: -0.02,
                fontSize: size,
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'DevIQ unifies your GitHub, LeetCode, and Codeforces data into one developer intelligence profile — a single score, your consistency fingerprint, and what to do next.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: secondary,
            height: 1.6,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 18),
        const _PlatformGlassStrip(),
        const SizedBox(height: 22),
        GlassPrimaryButton(
          label: 'Analyze Profile',
          icon: Icons.arrow_forward,
          onPressed: () => context.go('/analyze'),
        ),
        const SizedBox(height: 10),
        // Secondary paths stack full-width on phones so labels are
        // never clipped; side-by-side only when width is generous.
        LayoutBuilder(
          builder: (context, c) {
            final actions = [
              GlassGhostButton(
                label: 'Try Playground',
                icon: Icons.play_arrow_rounded,
                onTap: () => context.push('/playground'),
              ),
              GlassGhostButton(
                label: 'Compare Developers',
                icon: Icons.compare_arrows_rounded,
                onTap: () => context.push('/compare'),
              ),
            ];
            if (c.maxWidth >= 560) {
              return Row(
                children: [
                  Expanded(child: actions[0]),
                  const SizedBox(width: 10),
                  Expanded(child: actions[1]),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                actions[0],
                const SizedBox(height: 10),
                actions[1],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Platform identities fused into one frosted strip: recognizable
/// brand marks in their semantic colors, divided by hairlines.
class _PlatformGlassStrip extends StatelessWidget {
  const _PlatformGlassStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(DevPlatform p, String name) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PlatformIcons.of(p), size: 13, color: PlatformIcons.accentOf(p)),
        const SizedBox(width: 6),
        Text(
          name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontSize: 12.5,
          ),
        ),
      ],
    );

    final sep = Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: LiquidGlassTokens.edge(
        theme.brightness == Brightness.dark,
      ),
    );
    return LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      borderRadius: 14,
      blur: 12,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          item(DevPlatform.github, 'GitHub'),
          sep,
          item(DevPlatform.leetcode, 'LeetCode'),
          sep,
          item(DevPlatform.codeforces, 'Codeforces'),
        ],
      ),
    );
  }
}

/// Luminous divider between major home sections.
class HomeDivider extends StatelessWidget {
  const HomeDivider({super.key});

  @override
  Widget build(BuildContext context) => const GlassDivider();
}
