import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/deviq_colors.dart';
import '../../data/models/platform_models.dart';

/// Thin horizontal distribution bars (languages, difficulty splits).
class LanguageBars extends StatelessWidget {
  const LanguageBars({super.key, required this.entries, this.maxItems = 6});

  final Map<String, double> entries;
  final int maxItems;

  static const _palette = [
    DevIQColors.github,
    DevIQColors.codeforces,
    DevIQColors.teal,
    DevIQColors.leetcode,
    DevIQColors.success,
    DevIQColors.ai,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Text('No data yet',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.secondary));
    }
    final sorted = entries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = sorted.take(maxItems).toList();
    final total = shown.fold<double>(0, (a, e) => a + e.value);
    return Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(shown[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ),
              Text(
                total == 0
                    ? '—'
                    : '${(shown[i].value / total * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : shown[i].value / total,
              minHeight: 5,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(
                  _palette[i % _palette.length]),
            ),
          ),
          if (i != shown.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Minimal contribution line/area chart with muted grid + labels.
class ContributionChart extends StatelessWidget {
  const ContributionChart({super.key, required this.days, this.height = 150});

  final List<ContributionDay> days;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (days.isEmpty) return const SizedBox.shrink();
    final step = (days.length / 30).ceil().clamp(1, 99);
    final sampled = <FlSpot>[];
    for (var i = 0; i < days.length; i += step) {
      sampled.add(FlSpot(i.toDouble(), days[i].count.toDouble()));
    }
    final maxY =
        sampled.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY <= 0 ? 4 : maxY * 1.2),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                maxY <= 0 ? 1 : (maxY / 3).clamp(1, 9999).toDouble(),
            getDrawingHorizontalLine: (_) => FlLine(
                color: theme.dividerColor.withValues(alpha: 0.6),
                strokeWidth: 0.7),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: sampled,
              isCurved: true,
              barWidth: 1.6,
              color: DevIQColors.success,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: DevIQColors.success.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

/// GitHub-style contribution heatmap (7 rows × N weeks), theme-aware greens.
class ContributionHeatmap extends StatelessWidget {
  const ContributionHeatmap({super.key, required this.days});
  final List<ContributionDay> days;

  Color _cell(BuildContext context, int level) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const greens = [
      Color(0xFF161B22),
      Color(0xFF0E4429),
      Color(0xFF006D32),
      Color(0xFF26A641),
      Color(0xFF39D353),
    ];
    const lightGreens = [
      Color(0xFFEBEDF0),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
    final pal = dark ? greens : lightGreens;
    return pal[level.clamp(0, 4)];
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final weeks = <List<ContributionDay>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(
          i, i + 7 > days.length ? days.length : i + 7));
    }
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 3.0;
        final cell =
            ((c.maxWidth - gap * (weeks.length - 1)) / weeks.length)
                .clamp(4.0, 14.0);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in weeks)
                Padding(
                  padding: const EdgeInsets.only(right: gap),
                  child: Column(
                    children: [
                      for (final d in w)
                        Container(
                          width: cell,
                          height: cell,
                          margin: const EdgeInsets.only(bottom: gap),
                          decoration: BoxDecoration(
                            color: _cell(context, d.level),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Score-trend sparkline for history.
class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({super.key, required this.scores});
  final List<double> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.length < 2) return const SizedBox.shrink();
    final spots = [
      for (var i = 0; i < scores.length; i++)
        FlSpot(i.toDouble(), scores[i].clamp(0, 100)),
    ];
    return SizedBox(
      height: 90,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 1.8,
              color: Theme.of(context).colorScheme.onSurface,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
