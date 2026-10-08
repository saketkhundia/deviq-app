import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';
import '../../analyze/presentation/analyze_controller.dart';

/// History: score trend + previous analyses with details.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(historyProvider);
    return DevIQPage(
      reserveNav: false,
      children: [
        const DevIQSectionLabel('HISTORY'),
        const SizedBox(height: 10),
        Text(
          'Your progress\nover time.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 16),
        if (history.isEmpty)
          const EmptyState(
            icon: Icons.history_outlined,
            title: 'No analyses yet',
            message: 'Run your first analysis and it will be tracked here with score trends.',
          )
        else ...[
          DevIQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score trend',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ScoreTrendChart(scores: history.map((e) => e.score).toList()),
                const SizedBox(height: 4),
                Text(
                  '${history.length} analys${history.length == 1 ? 'is' : 'es'} · latest ${history.first.score.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final h in history)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DevIQCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  title: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: DevIQColors.scoreColor(h.score)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          h.score.toStringAsFixed(0),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: DevIQColors.scoreColor(h.score),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.github.isNotEmpty
                                  ? h.github
                                  : (h.leetcode.isNotEmpty
                                        ? h.leetcode
                                        : h.codeforces),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              Formatters.date(h.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    StatRow(label: 'GitHub stars', value: '${h.stars}'),
                    StatRow(label: 'Repositories', value: '${h.repos}'),
                    if (h.language.isNotEmpty)
                      StatRow(label: 'Top language', value: h.language),
                    StatRow(
                      label: 'LeetCode solved',
                      value:
                          '${h.lcSolved} (E${h.lcEasy}/M${h.lcMedium}/H${h.lcHard})',
                    ),
                    StatRow(
                      label: 'Codeforces',
                      value: h.cfRating > 0
                          ? '${h.cfRating} · ${h.cfRank}'
                          : '—',
                    ),
                    StatRow(
                      label: 'CF problems/contests',
                      value: '${h.cfProblems}/${h.cfContests}',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text(
                      'All local analysis records will be removed.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  ref.read(historyProvider.notifier).clear();
                }
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear history'),
            ),
          ),
        ],
      ],
    );
  }
}
