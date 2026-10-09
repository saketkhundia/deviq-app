import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/platform_models.dart';
import '../../../../shared/widgets/deviq_widgets.dart';

/// Contribution activity: totals, streaks and a responsive heatmap with
/// month + weekday labels and an intensity legend. The heatmap scrolls
/// horizontally INSIDE the card — the page never overflows.
class ActivitySection extends StatelessWidget {
  const ActivitySection({super.key, required this.data});

  final ContributionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTRIBUTION ACTIVITY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Right-aligned stats that wrap instead of clipping on
                // narrow phones.
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _HeadStat(
                      value: Formatters.integer(data.total),
                      caption: 'Contributions',
                    ),
                    _HeadStat(
                      value: '${data.currentStreak}d',
                      caption: 'Streak',
                    ),
                    _HeadStat(
                      value: '${data.longestStreak}d',
                      caption: 'Longest',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _LabeledHeatmap(days: data.days),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _Legend(colorFor: (i) => _staticColor(context, i)),
          ),
        ],
      ),
    );
  }
}

class _HeadStat extends StatelessWidget {
  const _HeadStat({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          caption,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Theme-aware heatmap cell palette shared by the grid and the legend.
Color _staticColor(BuildContext context, int level) {
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
  return (dark ? greens : lightGreens)[level.clamp(0, 4)];
}

class _LabeledHeatmap extends StatelessWidget {
  const _LabeledHeatmap({required this.days});

  final List<ContributionDay> days;

  static const _cell = 11.0;
  static const _gap = 3.0;
  static const _gutter = 30.0;

  Color _color(BuildContext context, int level) => _staticColor(context, level);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (days.isEmpty) {
      return Text(
        'No activity data.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.secondary,
        ),
      );
    }
    // Chronological weeks (7-day columns, Monday-first not assumed —
    // columns simply chunk the ordered series).
    final weeks = <List<ContributionDay>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
    }
    final monthFmt = DateFormat('MMM');
    final labels = <String>[];
    var prevMonth = -1;
    for (final w in weeks) {
      final d = DateTime.tryParse(w.first.date);
      final m = d?.month ?? -1;
      if (m != prevMonth && m != -1) {
        labels.add(monthFmt.format(d!));
        prevMonth = m;
      } else {
        labels.add('');
      }
    }
    const weekdays = ['Mon', '', 'Wed', '', 'Fri', '', ''];
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.secondary,
      fontSize: 10,
    );
    Widget cell(ContributionDay d) => Container(
      width: _cell,
      height: _cell,
      decoration: BoxDecoration(
        color: _color(context, d.level),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              for (var r = 0; r < 7; r++)
                Container(
                  width: _gutter,
                  height: _cell,
                  margin: const EdgeInsets.only(bottom: _gap),
                  alignment: Alignment.centerLeft,
                  child: Text(weekdays[r], style: labelStyle),
                ),
            ],
          ),
          const SizedBox(width: 6),
          for (var wi = 0; wi < weeks.length; wi++)
            Padding(
              padding: const EdgeInsets.only(right: _gap),
              child: Column(
                children: [
                  SizedBox(
                    height: 16,
                    child: Text(labels[wi], style: labelStyle),
                  ),
                  for (final d in weeks[wi])
                    Padding(
                      padding: const EdgeInsets.only(bottom: _gap),
                      child: cell(d),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colorFor});

  final Color Function(int level) colorFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Less',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 6),
        for (var i = 0; i <= 4; i++)
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: colorFor(i),
              borderRadius: BorderRadius.circular(2.5),
              border: Border.all(color: theme.dividerColor),
            ),
          ),
        const SizedBox(width: 3),
        Text(
          'More',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
