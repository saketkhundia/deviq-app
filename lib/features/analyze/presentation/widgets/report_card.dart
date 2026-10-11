import 'package:flutter/material.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/analysis_models.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/platform_icons.dart';
import '../../../../shared/widgets/score_ring.dart';

/// ANALYSIS REPORT instrument in liquid glass: combined title,
/// platform lenses, classification, signal-green score ring and a
/// data-derived summary. Never fabricates — every value comes from
/// [result].
class AnalysisReportCard extends StatelessWidget {
  const AnalysisReportCard({super.key, required this.result});

  final AnalysisResult result;

  String _title() {
    final parts = [
      result.githubUsername,
      result.leetcodeUsername,
      result.codeforcesHandle,
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' / ');
  }

  String _summary() {
    final bits = <String>[];
    final g = result.github;
    if (g != null) {
      bits.add(
        '${Formatters.integer(g.totalProjects)} repos · ${Formatters.compact(g.totalStars)} stars',
      );
    }
    final lc = result.leetcode;
    if (lc != null) {
      final solved = lc.totalSolved > 0
          ? lc.totalSolved
          : lc.easySolved + lc.mediumSolved + lc.hardSolved;
      bits.add('${Formatters.integer(solved)} LeetCode solved');
    }
    final cf = result.codeforces;
    if (cf != null && cf.rating > 0) {
      bits.add(
        'Codeforces ${cf.rating}'
        '${cf.rank.isNotEmpty ? ' (${cf.rank})' : ''}',
      );
    }
    if (bits.isEmpty) return 'Unified score from connected platforms.';
    return '${bits.join(' · ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final score = result.unifiedScore;
    final present = <DevPlatform>[
      if (result.github != null) DevPlatform.github,
      if (result.leetcode != null) DevPlatform.leetcode,
      if (result.codeforces != null) DevPlatform.codeforces,
    ];
    return LiquidGlass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSectionHeader(index: '01', title: 'Analysis report'),
          const SizedBox(height: 10),
          Text(
            _title(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in present) _PlatformLens(platform: p),
              _VerdictLens(score: score),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: ScoreRing(
              score: score,
              label: 'UNIFIED SCORE',
              diameter: 132,
              duration: const Duration(milliseconds: 1100),
              color: DevIQColors.signalFor(dark),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _summary(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: LiquidGlassTokens.edge(dark)),
              ),
            ),
            child: Row(
              children: [
                if (result.githubScore != null)
                  Expanded(
                    child: _MiniScore(
                      label: 'GitHub',
                      value: result.githubScore!,
                      color: DevIQColors.github,
                    ),
                  ),
                if (result.leetcodeScore != null) ...[
                  _VLens(theme: theme),
                  Expanded(
                    child: _MiniScore(
                      label: 'LeetCode',
                      value: result.leetcodeScore!,
                      color: DevIQColors.leetcode,
                    ),
                  ),
                ],
                if (result.codeforcesScore != null) ...[
                  _VLens(theme: theme),
                  Expanded(
                    child: _MiniScore(
                      label: 'Codeforces',
                      value: result.codeforcesScore!,
                      color: DevIQColors.codeforces,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VLens extends StatelessWidget {
  const _VLens({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.dividerColor.withValues(alpha: 0),
          theme.dividerColor,
          theme.dividerColor.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

class _VerdictLens extends StatelessWidget {
  const _VerdictLens({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = DevIQColors.scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8),
        ],
      ),
      child: Text(
        ScoreUtils.verdict(score),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Frosted platform lens in the platform's semantic color.
class _PlatformLens extends StatelessWidget {
  const _PlatformLens({required this.platform});

  final DevPlatform platform;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = PlatformIcons.accentOf(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        PlatformIcons.labelOf(platform),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
