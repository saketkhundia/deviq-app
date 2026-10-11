import 'package:flutter/material.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/analysis_models.dart';
import '../../../../shared/widgets/signal.dart';
import 'liquid_glass.dart';

/// 02 / Activity fingerprint — rebuilt from scratch in liquid glass.
///
/// Renders the REAL contribution calendar only, floating on a frosted
/// panel with tabular stat instruments. When no contribution data
/// exists the section says so plainly; activity is never synthesized
/// to fill the page.
class ActivityFingerprint extends StatelessWidget {
  const ActivityFingerprint({super.key, required this.result});

  final AnalysisResult? result;

  @override
  Widget build(BuildContext context) {
    final data = result?.contributions;
    final username = (result?.githubUsername ?? '').trim();

    if (data == null || data.days.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionHeader(
            index: '02',
            title: 'Activity fingerprint',
            caption: result == null
                ? 'Your contribution history will appear here after your first GitHub analysis.'
                : username.isEmpty
                    ? 'No GitHub account in this analysis — add one to map your consistency.'
                    : 'No contribution data for @$username — the account may be new or unreachable.',
          ),
          const SizedBox(height: 14),
          const _FingerprintEmpty(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSectionHeader(
          index: '02',
          title: 'Activity fingerprint',
          caption: '@${data.username} · ${Formatters.integer(data.total)} contributions in period',
        ),
        const SizedBox(height: 14),
        LiquidGlass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FingerprintStat(
                    value: Formatters.integer(data.total),
                    caption: 'CONTRIBUTIONS',
                  ),
                  _FingerprintStat(
                    value: '${data.currentStreak}d',
                    caption: 'CURRENT STREAK',
                    accent: true,
                  ),
                  _FingerprintStat(
                    value: '${data.longestStreak}d',
                    caption: 'LONGEST',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SignalHeatmap(days: data.days),
            ],
          ),
        ),
      ],
    );
  }
}

class _FingerprintStat extends StatelessWidget {
  const _FingerprintStat({
    required this.value,
    required this.caption,
    this.accent = false,
  });

  final String value;
  final String caption;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final glow = DevIQColors.signalFor(dark);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SignalType.tabular(
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.01,
              ),
            ),
          ),
          // Streak marker: one luminous signal dash.
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: accent
                  ? glow
                  : theme.colorScheme.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
              boxShadow: accent
                  ? [
                      BoxShadow(
                        color: glow.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Honest empty fingerprint: one frosted tile suggesting the shape of
/// the data to come — no fabricated cells.
class _FingerprintEmpty extends StatelessWidget {
  const _FingerprintEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      borderRadius: 16,
      blur: 12,
      child: Row(
        children: [
          Icon(
            Icons.grid_on_outlined,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No activity mapped yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
