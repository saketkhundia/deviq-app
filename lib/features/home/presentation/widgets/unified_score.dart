import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/analysis_models.dart';
import '../../../../shared/widgets/score_ring.dart';
import '../../../../shared/widgets/signal.dart';
import '../../../analyze/presentation/analyze_controller.dart';
import 'liquid_glass.dart';

/// 01 / Unified score — the signature DevIQ instrument, rebuilt from
/// scratch in liquid glass.
///
/// The same strict live-data state machine:
///   - session [AnalysisResult] → full instrument with real scores;
///   - persisted [HistoryRecord] only → last-known score, captioned;
///   - nothing → onboarding state with an empty track and no numbers.
///
/// Fabricated scores are never shown. The numeral and ring arc are
/// always the DevIQ signal green; platform rows keep their own
/// semantic colors. Every surface is refractive glass.
class UnifiedScoreSection extends ConsumerWidget {
  const UnifiedScoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyzeProvider);
    final history = ref.watch(historyProvider);
    final result = state.status == AnalyzeStatus.success ? state.result : null;
    final last = history.isNotEmpty ? history.first : null;

    if (result != null && result.hasData) {
      return _LiveScore(result: result, history: history);
    }
    if (last != null) {
      return _LastScore(last: last);
    }
    return const _OnboardingScore();
  }
}

class _LiveScore extends StatelessWidget {
  const _LiveScore({required this.result, required this.history});

  final AnalysisResult result;
  final List<HistoryRecord> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final signal = DevIQColors.signalFor(dark);
    final unified = result.unifiedScore;
    final platforms = [
      result.githubScore,
      result.leetcodeScore,
      result.codeforcesScore,
    ].whereType<double>().length;

    final names = [
      if (result.githubUsername.isNotEmpty) '@${result.githubUsername}',
      if (result.leetcodeUsername.isNotEmpty) '@${result.leetcodeUsername}',
      if (result.codeforcesHandle.isNotEmpty) '@${result.codeforcesHandle}',
    ].take(2).join('  ·  ');
    final ringDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1400);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSectionHeader(
          index: '01',
          title: 'Unified score',
          caption: names.isEmpty
              ? 'Analyzed ${Formatters.timeAgo(result.analyzedAt.toIso8601String())}'
              : '$names · analyzed ${Formatters.timeAgo(result.analyzedAt.toIso8601String())}',
        ),
        const SizedBox(height: 16),
        LiquidGlass(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScoreRing(
                score: unified,
                color: signal,
                diameter: 132,
                duration: ringDuration,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ScoreUtils.verdict(unified),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unified across $platforms platform${platforms == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DeltaLine(
                      history: history,
                      current: unified,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (result.github != null)
          _GlassLedgerRow(
            dot: DevIQColors.github,
            name: 'GitHub',
            evidence:
                '${result.github!.totalProjects} repos · ${Formatters.compact(result.github!.totalStars)} stars · ${result.github!.mostUsedLanguage.isEmpty ? '—' : result.github!.mostUsedLanguage}',
            score: result.githubScore ?? 0,
            delta: (result.githubScore ?? 0) - unified,
          ),
        if (result.leetcode != null)
          _GlassLedgerRow(
            dot: DevIQColors.leetcode,
            name: 'LeetCode',
            evidence:
                '${result.leetcode!.totalSolved} solved · ${result.leetcode!.hardSolved} hard',
            score: result.leetcodeScore ?? 0,
            delta: (result.leetcodeScore ?? 0) - unified,
          ),
        if (result.codeforces != null)
          _GlassLedgerRow(
            dot: DevIQColors.codeforces,
            name: 'Codeforces',
            evidence:
                '${result.codeforces!.rating} · ${result.codeforces!.rank.isEmpty ? 'Unrated' : result.codeforces!.rank}',
            score: result.codeforcesScore ?? 0,
            delta: (result.codeforcesScore ?? 0) - unified,
          ),
      ],
    );
  }
}

/// One frosted ledger row: brand dot, name, mono evidence, tabular
/// score with vs-unified delta, and a luminous micro-bar.
class _GlassLedgerRow extends StatelessWidget {
  const _GlassLedgerRow({
    required this.dot,
    required this.name,
    required this.evidence,
    required this.score,
    required this.delta,
  });

  final Color dot;
  final String name;
  final String evidence;
  final double score;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final secondary = theme.colorScheme.secondary;
    final up = delta >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LiquidGlass(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
        borderRadius: 16,
        blur: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dot.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        evidence,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SignalType.mono(context, size: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: SignalType.tabular(
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${up ? '+' : ''}${delta.toStringAsFixed(0)} vs unified',
                      style: SignalType.tabular(
                        theme.textTheme.labelSmall?.copyWith(
                          color: up
                              ? DevIQColors.signalFor(dark)
                              : secondary,
                          fontWeight: up ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            GlassBar(value: score / 100, color: dot, height: 4),
          ],
        ),
      ),
    );
  }
}

/// Change since the previous persisted analysis. Real history only.
class _DeltaLine extends StatelessWidget {
  const _DeltaLine({required this.history, required this.current});

  final List<HistoryRecord> history;
  final double current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final secondary = theme.colorScheme.secondary;
    if (history.length < 2) {
      return Text(
        'First recorded analysis',
        style: theme.textTheme.bodySmall?.copyWith(
          color: secondary,
          fontSize: 12.5,
        ),
      );
    }
    final delta = current - history[1].score;
    final flat = delta.abs() < 0.05;
    return Text(
      flat
          ? 'No change since last analysis'
          : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} since last analysis',
      style: SignalType.tabular(
        theme.textTheme.bodySmall?.copyWith(
          color: flat
              ? secondary
              : (delta > 0 ? DevIQColors.signalFor(dark) : DevIQColors.error),
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

/// Last-known score from persisted history, on glass. Every number is
/// captioned as the last analysis — never presented as live.
class _LastScore extends StatelessWidget {
  const _LastScore({required this.last});
  final HistoryRecord last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final signal = DevIQColors.signalFor(dark);
    final ringDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1400);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSectionHeader(
          index: '01',
          title: 'Unified score',
          caption:
              'Last analysis ${Formatters.date(last.date)} — re-run to refresh.',
        ),
        const SizedBox(height: 16),
        LiquidGlass(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScoreRing(
                score: last.score,
                color: signal,
                diameter: 132,
                duration: ringDuration,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ScoreUtils.verdict(last.score),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From your last analysis',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassGhostButton(
          label: 'Re-run analysis',
          icon: Icons.refresh,
          onTap: () => context.go('/analyze'),
        ),
      ],
    );
  }
}

/// Onboarding instrument: frosted panel, empty track, `--` numeral,
/// one directive. No numbers are invented to fill the space.
class _OnboardingScore extends StatelessWidget {
  const _OnboardingScore();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlassSectionHeader(
          index: '01',
          title: 'Unified score',
          caption:
              'Connect a platform to compute your DevIQ score — GitHub, LeetCode, or Codeforces.',
        ),
        const SizedBox(height: 16),
        LiquidGlass(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _EmptyTrack(diameter: 132),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No profile yet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your score appears here after your first analysis.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassPrimaryButton(
          label: 'Analyze Profile',
          icon: Icons.arrow_forward,
          onPressed: () => context.go('/analyze'),
        ),
      ],
    );
  }
}

/// Static empty instrument track with a `--` numeral.
class _EmptyTrack extends StatelessWidget {
  const _EmptyTrack({required this.diameter});
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _TrackPainter(color: theme.dividerColor),
        child: Center(
          child: Text(
            '––',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.secondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide / 2) - 4;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.color != color;
}
