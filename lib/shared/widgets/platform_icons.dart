import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../core/theme/deviq_colors.dart';
import 'deviq_widgets.dart';

/// Canonical platform identity: official brand glyphs (Simple Icons,
/// bundled offline — no network fetch, no emoji substitutes) paired with
/// the DevIQ semantic accent per platform.
///
/// Every screen must source platform icons/colors here so GitHub,
/// LeetCode and Codeforces look identical everywhere.
enum DevPlatform { github, leetcode, codeforces }

class PlatformIcons {
  const PlatformIcons._();

  static IconData of(DevPlatform platform) => switch (platform) {
    DevPlatform.github => SimpleIcons.github,
    DevPlatform.leetcode => SimpleIcons.leetcode,
    DevPlatform.codeforces => SimpleIcons.codeforces,
  };

  static Color accentOf(DevPlatform platform) => switch (platform) {
    DevPlatform.github => DevIQColors.github,
    DevPlatform.leetcode => DevIQColors.leetcode,
    DevPlatform.codeforces => DevIQColors.codeforces,
  };

  static String labelOf(DevPlatform platform) => switch (platform) {
    DevPlatform.github => 'GitHub',
    DevPlatform.leetcode => 'LeetCode',
    DevPlatform.codeforces => 'Codeforces',
  };
}

/// Section header pairing the official brand glyph with the standard
/// uppercase section label. Bounded (icon + flexible label) — safe in
/// any phone viewport.
class PlatformSectionLabel extends StatelessWidget {
  const PlatformSectionLabel({
    super.key,
    required this.platform,
    required this.label,
  });

  final DevPlatform platform;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        PlatformIcons.of(platform),
        size: 14,
        color: PlatformIcons.accentOf(platform),
      ),
      const SizedBox(width: 8),
      Expanded(child: DevIQSectionLabel(label)),
    ],
  );
}
