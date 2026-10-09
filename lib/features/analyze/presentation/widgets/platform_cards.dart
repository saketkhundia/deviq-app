import 'package:flutter/material.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/analysis_models.dart';
import '../../../../shared/widgets/charts.dart';
import '../../../../shared/widgets/deviq_widgets.dart';
import '../../../../shared/widgets/platform_icons.dart';

/// Platform cards mirroring the web reference: brand header with username
/// and CONNECTED pill, hairline stat rows (muted label, bold colored
/// value), then platform-specific breakdowns. Stacked on mobile.
/// Every value comes from the backend response; metrics the backend does
/// not provide are omitted rather than faked.
class GithubPlatformCard extends StatelessWidget {
  const GithubPlatformCard({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final g = result.github!;
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(platform: DevPlatform.github, username: g.username),
          _StatRow(
            label: 'Repositories',
            value: Formatters.integer(g.totalProjects),
            color: DevIQColors.github,
          ),
          _StatRow(
            label: 'Stars',
            value: Formatters.integer(g.totalStars),
            color: DevIQColors.warning,
          ),
          _StatRow(
            label: 'Recent Active',
            value: Formatters.integer(g.recentActive),
            last: false,
          ),
          _StatRow(
            label: 'Skill Score',
            value: g.skillScore > 0
                ? '${g.skillScore.toStringAsFixed(0)}/100'
                : '—',
            color: DevIQColors.success,
          ),
          _StatRow(
            label: 'Top Language',
            value: g.mostUsedLanguage.isEmpty ? '—' : g.mostUsedLanguage,
            color: DevIQColors.github,
            last: true,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _Kicker('LANGUAGES'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: LanguageBars(
              entries: g.languageDistribution.map(
                (k, v) => MapEntry(k, v.toDouble()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeetcodePlatformCard extends StatelessWidget {
  const LeetcodePlatformCard({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final l = result.leetcode!;
    final total = l.totalSolved > 0
        ? l.totalSolved
        : l.easySolved + l.mediumSolved + l.hardSolved;
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(platform: DevPlatform.leetcode, username: l.username),
          _StatRow(
            label: 'Total Solved',
            value: Formatters.integer(total),
            color: DevIQColors.leetcode,
          ),
          _StatRow(
            label: 'Global Rank',
            value: l.ranking > 0 ? '#${Formatters.integer(l.ranking)}' : '—',
          ),
          _StatRow(
            label: 'Contest Rating',
            value: l.contestRating > 0 ? '${l.contestRating}' : '—',
            color: DevIQColors.codeforces,
          ),
          if (l.contestsAttended > 0 || l.topPercentage > 0) ...[
            _StatRow(
              label: 'Contests',
              value: l.contestsAttended > 0
                  ? Formatters.integer(l.contestsAttended)
                  : '—',
            ),
            _StatRow(
              label: 'Top %',
              value: l.topPercentage > 0
                  ? '${_trimPct(l.topPercentage)}%'
                  : '—',
              color: DevIQColors.success,
              last: true,
            ),
          ] else
            _StatRow(
              label: 'Reputation',
              value: l.reputation > 0 ? Formatters.compact(l.reputation) : '—',
              last: true,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _DifficultyTile(
                  value: l.easySolved,
                  label: 'EASY',
                  color: DevIQColors.success,
                ),
                const SizedBox(width: 10),
                _DifficultyTile(
                  value: l.mediumSolved,
                  label: 'MED',
                  color: DevIQColors.warning,
                ),
                const SizedBox(width: 10),
                _DifficultyTile(
                  value: l.hardSolved,
                  label: 'HARD',
                  color: DevIQColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CodeforcesPlatformCard extends StatelessWidget {
  const CodeforcesPlatformCard({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final c = result.codeforces!;
    final rc = DevIQColors.cfRankColor(c.rank);
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(platform: DevPlatform.codeforces, username: c.username),
          _StatRow(
            label: 'Current Rating',
            value: c.rating > 0 ? '${c.rating}' : '—',
            color: DevIQColors.codeforces,
          ),
          _StatRow(
            label: 'Peak Rating',
            value: c.maxRating > 0 ? '${c.maxRating}' : '—',
            color: DevIQColors.github,
          ),
          _StatRow(
            label: 'Rank',
            value: c.rank.isEmpty ? '—' : c.rank,
            color: rc,
          ),
          _StatRow(
            label: 'Peak Rank',
            value: c.maxRank.isEmpty ? '—' : c.maxRank,
            color: rc,
          ),
          _StatRow(
            label: 'Problems Solved',
            value: c.problemsSolved > 0
                ? Formatters.integer(c.problemsSolved)
                : '—',
            color: DevIQColors.success,
          ),
          _StatRow(label: 'Contests', value: '${c.contestsParticipated}'),
          _StatRow(
            label: 'Contribution',
            value: '${c.contribution >= 0 ? '+' : ''}${c.contribution}',
            color: DevIQColors.success,
            last: true,
          ),
        ],
      ),
    );
  }
}

/// Brand header: icon + name/username with CONNECTED pill.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.platform, required this.username});

  final DevPlatform platform;
  final String username;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = PlatformIcons.accentOf(platform);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(PlatformIcons.of(platform), size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PlatformIcons.labelOf(platform),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (username.isNotEmpty)
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DevIQRadius.pill),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
              color: accent.withValues(alpha: 0.08),
            ),
            child: Text(
              'CONNECTED',
              style: TextStyle(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: theme.colorScheme.secondary,
      ),
    );
  }
}

/// Hairline stat row: muted label left, bold value right.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.color,
    this.last = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
          bottom: last
              ? BorderSide(color: theme.dividerColor)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              Formatters.integer(value),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trims a percentile to at most 2 decimals without trailing zeros
/// (69.57% stays 69.57%, matching the web reference).
String _trimPct(double v) =>
    v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
