import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/github_models.dart';
import '../../../../shared/widgets/deviq_widgets.dart';

/// GitHub Insights panel: titled frame with an ADVANCED tag containing
/// the most-complex (and, when different, most-starred) repository,
/// derived transparently from real repository data.
class GithubInsights extends StatelessWidget {
  const GithubInsights({super.key, required this.github});

  final GithubStats github;

  /// Documented complexity proxy: log-scaled size plus traction signals.
  static double complexityOf(GithubRepo r) =>
      math.log(r.sizeKb + 1) * 2 +
      r.stars * 0.5 +
      r.forks * 0.3 +
      r.openIssues * 0.2 +
      r.topics.length * 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repos = github.repositories.where((r) => !r.isFork).toList();
    if (repos.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb_outlined,
        title: 'No insights yet',
        message: 'Insights appear once repositories are analyzed.',
      );
    }
    repos.sort((a, b) => complexityOf(b).compareTo(complexityOf(a)));
    final complex = repos.first;
    final byStars = repos.toList()..sort((a, b) => b.stars.compareTo(a.stars));
    final starred = byStars.first;
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'GitHub Insights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'ADVANCED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    letterSpacing: 0.6,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _ComplexCard(repo: complex, fileCount: null),
          ),
          if (starred.fullName != complex.fullName)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _InsightCard(
                kicker: 'MOST STARRED',
                name: starred.fullName.isEmpty
                    ? starred.name
                    : starred.fullName,
                lines: [
                  'Stars · ${Formatters.compact(starred.stars)} · Forks · ${Formatters.compact(starred.forks)}',
                  if (starred.description.isNotEmpty) starred.description,
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Most-complex repository card. When the backend tree endpoint has been
/// queried for this repo ([fileCount] non-null) the real file count is
/// shown; otherwise size + traction signals describe the pick.
class _ComplexCard extends StatelessWidget {
  const _ComplexCard({required this.repo, required this.fileCount});

  final GithubRepo repo;
  final int? fileCount;

  @override
  Widget build(BuildContext context) {
    final bits = <String>[];
    if (fileCount != null) {
      bits.add('${Formatters.integer(fileCount!)} files · High complexity');
    } else {
      bits.add(
        '${repo.sizeKb > 0 ? '${Formatters.compact(repo.sizeKb)} KB · ' : ''}High complexity',
      );
      bits.add(
        '${Formatters.compact(repo.stars)} stars · ${Formatters.compact(repo.forks)} forks',
      );
    }
    return _InsightCard(
      kicker: 'MOST COMPLEX REPO',
      amber: true,
      name: repo.fullName.isEmpty ? repo.name : repo.fullName,
      lines: bits,
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.kicker,
    required this.name,
    required this.lines,
    this.amber = false,
  });

  final String kicker;
  final String name;
  final List<String> lines;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: amber ? DevIQColors.warning : theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                l,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
