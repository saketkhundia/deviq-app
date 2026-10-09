import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../shared/widgets/deviq_widgets.dart';

/// Illustrative score preview mirroring the desktop hero card.
/// Static sample values only — never presented as the user's live data
/// (see the "Sample preview" caption). Bounded; never widens its parent.
class DeveloperScorePreview extends StatelessWidget {
  const DeveloperScorePreview({super.key});

  static const _metrics = [
    ('GitHub', '82'),
    ('LeetCode', '74'),
    ('Codeforces', '68'),
    ('DevIQ', '78'),
  ];

  // Gentle upward sample trend for the decorative chart.
  static const _trend = [
    38.0,
    42.0,
    45.0,
    44.0,
    49.0,
    53.0,
    52.0,
    57.0,
    61.0,
    64.0,
    70.0,
    78.0,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DEVELOPER SCORE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DevIQRadius.pill),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  'Sample preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final twoCols = c.maxWidth >= 280;
              if (!twoCols) {
                return Column(
                  children: [
                    for (final m in _metrics)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PreviewMetric(label: m.$1, value: m.$2),
                      ),
                  ],
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 84,
                ),
                itemCount: _metrics.length,
                itemBuilder: (context, i) => _PreviewMetric(
                  label: _metrics[i].$1,
                  value: _metrics[i].$2,
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'PROGRESS TREND',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          const _TrendChart(),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TintPill(
                label: 'Role Fit: Full-Stack',
                color: DevIQColors.success,
              ),
              _TintPill(label: 'AI Plan Ready', color: DevIQColors.error),
              _TintPill(label: 'Heatmap Active', color: DevIQColors.warning),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Illustrative preview — run Analyze for your live scores.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DevIQRadius.card),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' /100',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
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

/// Minimalist decorative trend line (GitHub blue), no axes or grid.
class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < DeveloperScorePreview._trend.length; i++)
        FlSpot(i.toDouble(), DeveloperScorePreview._trend[i]),
    ];
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: Semantics(
        label: 'Sample progress trend chart, trending upward',
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
                barWidth: 2,
                color: DevIQColors.github,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      index == bar.spots.length - 1
                      ? FlDotCirclePainter(
                          radius: 3,
                          color: DevIQColors.github,
                          strokeWidth: 0,
                        )
                      : FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                          strokeWidth: 0,
                        ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: DevIQColors.github.withValues(alpha: 0.1),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
                  strokeWidth: 1,
                ),
              ],
            ),
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }
}

/// Tinted status pill matching the web preview (green / red / amber).
class _TintPill extends StatelessWidget {
  const _TintPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DevIQRadius.pill),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}
