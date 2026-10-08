import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../../data/models/analysis_models.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../app/providers/app_providers.dart';
import 'analyze_controller.dart';

/// Developer analytics: username inputs → unified score + platform cards +
/// repos, languages, heatmap, difficulty splits.
class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  final _form = GlobalKey<FormState>();
  final _gh = TextEditingController();
  final _lc = TextEditingController();
  final _cf = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _gh.dispose();
    _lc.dispose();
    _cf.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    if (_prefilled) return;
    _prefilled = true;
    final last = await ref.read(prefsStoreProvider).lastUsernames();
    _gh.text = last['github'] ?? '';
    _lc.text = last['leetcode'] ?? '';
    _cf.text = last['codeforces'] ?? '';
    if (mounted) setState(() {});
  }

  void _run() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(analyzeProvider.notifier)
        .run(github: _gh.text, leetcode: _lc.text, codeforces: _cf.text);
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    final theme = Theme.of(context);
    final state = ref.watch(analyzeProvider);
    return DevIQPage(
      reserveNav: true,
      children: [
        const DevIQSectionLabel('DEVELOPER ANALYTICS'),
        const SizedBox(height: 10),
        Text(
          'Measure what\nactually matters.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.02,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Connect GitHub, LeetCode and Codeforces to get a unified score, deep analytics, and AI-powered insights.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        DevIQCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DevIQTextField(
                  controller: _gh,
                  label: 'GitHub username',
                  hint: 'torvalds',
                  prefixIcon: Icons.hub_outlined,
                  monospace: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.username(v, required: false),
                ),
                const SizedBox(height: 12),
                DevIQTextField(
                  controller: _lc,
                  label: 'LeetCode username',
                  hint: 'leetcode_username',
                  prefixIcon: Icons.code_outlined,
                  monospace: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.username(v, required: false),
                ),
                const SizedBox(height: 12),
                DevIQTextField(
                  controller: _cf,
                  label: 'Codeforces handle',
                  hint: 'tourist',
                  prefixIcon: Icons.emoji_events_outlined,
                  monospace: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _run(),
                  validator: (v) => Validators.username(v, required: false),
                ),
                const SizedBox(height: 16),
                DevIQButton(
                  label: 'Run Analysis',
                  icon: Icons.play_arrow,
                  loading: state.status == AnalyzeStatus.loading,
                  onPressed: _run,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        switch (state.status) {
          AnalyzeStatus.loading => const Column(
            children: [
              SkeletonCard(height: 220),
              SizedBox(height: 10),
              SkeletonCard(height: 160),
            ],
          ),
          AnalyzeStatus.failure => ErrorState(
            message: state.error ?? 'Analysis failed.',
            onRetry: _run,
          ),
          AnalyzeStatus.success => _Results(
            result: state.result!,
            failed: state.failedPlatforms,
          ),
          AnalyzeStatus.idle => EmptyState(
            icon: Icons.analytics_outlined,
            title: 'No analysis yet',
            message: 'Enter at least one username above and run an analysis to see your unified DevIQ score.',
          ),
        },
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.failed});
  final AnalysisResult result;
  final List<String> failed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = result.unifiedScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (failed.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DevIQColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: DevIQColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Partial data: ${failed.join(', ')} couldn\u2019t be reached. Showing the rest.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        DevIQCard(
          child: Column(
            children: [
              ScoreRing(score: score, label: 'DEVIQ SCORE'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DevIQColors.scoreColor(score).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: DevIQColors.scoreColor(score)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  ScoreUtils.verdict(score),
                  style: TextStyle(
                    color: DevIQColors.scoreColor(score),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (result.githubScore != null)
                    Expanded(
                      child: _MiniScore(
                        label: 'GitHub',
                        value: result.githubScore!,
                        color: DevIQColors.github,
                      ),
                    ),
                  if (result.leetcodeScore != null)
                    Expanded(
                      child: _MiniScore(
                        label: 'LeetCode',
                        value: result.leetcodeScore!,
                        color: DevIQColors.leetcode,
                      ),
                    ),
                  if (result.codeforcesScore != null)
                    Expanded(
                      child: _MiniScore(
                        label: 'Codeforces',
                        value: result.codeforcesScore!,
                        color: DevIQColors.codeforces,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (result.github != null) ...[
          const DevIQSectionLabel('GITHUB', accent: DevIQColors.github),
          const SizedBox(height: 10),
          _GithubSection(result: result),
          const SizedBox(height: 16),
        ],
        if (result.leetcode != null) ...[
          const DevIQSectionLabel('LEETCODE', accent: DevIQColors.leetcode),
          const SizedBox(height: 10),
          _LeetcodeSection(result: result),
          const SizedBox(height: 16),
        ],
        if (result.codeforces != null) ...[
          const DevIQSectionLabel('CODEFORCES', accent: DevIQColors.codeforces),
          const SizedBox(height: 10),
          _CodeforcesSection(result: result),
          const SizedBox(height: 16),
        ],
      ],
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
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _GithubSection extends StatelessWidget {
  const _GithubSection({required this.result});
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final g = result.github!;
    final theme = Theme.of(context);
    final c = result.contributions;
    final topRepos = g.repositories.toList()
      ..sort((a, b) => b.stars.compareTo(a.stars));
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Repositories',
                value: Formatters.integer(g.totalProjects),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Stars',
                value: Formatters.compact(g.totalStars),
                accent: DevIQColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Forks',
                value: Formatters.compact(g.totalForks),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DevIQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language distribution',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (g.mostUsedLanguage.isNotEmpty)
                Text(
                  'Top language · ${g.mostUsedLanguage}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              const SizedBox(height: 12),
              LanguageBars(
                entries: g.languageDistribution.map(
                  (k, v) => MapEntry(k, v.toDouble()),
                ),
              ),
            ],
          ),
        ),
        if (c != null && c.days.isNotEmpty) ...[
          const SizedBox(height: 10),
          DevIQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Contributions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${Formatters.integer(c.total)} total',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ContributionHeatmap(days: c.days),
                const SizedBox(height: 12),
                ContributionChart(days: c.days, height: 120),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: 'Current streak',
                        value: '${c.currentStreak}d',
                        accent: DevIQColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricCard(
                        label: 'Longest streak',
                        value: '${c.longestStreak}d',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (topRepos.isNotEmpty) ...[
          const SizedBox(height: 10),
          DevIQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top repositories',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final r in topRepos.take(5))
                  _RepoTile(
                    name: r.fullName.isEmpty ? r.name : r.fullName,
                    url: r.htmlUrl,
                    description: r.description,
                    language: r.language,
                    stars: r.stars,
                    forks: r.forks,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RepoTile extends StatelessWidget {
  const _RepoTile({
    required this.name,
    required this.url,
    required this.description,
    required this.language,
    required this.stars,
    required this.forks,
  });

  final String name;
  final String url;
  final String description;
  final String language;
  final int stars;
  final int forks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: url.isEmpty
          ? null
          : () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (description.isNotEmpty)
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (language.isNotEmpty) ...[
                  const Icon(Icons.circle, size: 8),
                  const SizedBox(width: 4),
                  Text(language, style: theme.textTheme.labelSmall),
                  const SizedBox(width: 12),
                ],
                Icon(
                  Icons.star_border,
                  size: 13,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 3),
                Text(
                  Formatters.compact(stars),
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.fork_right,
                  size: 13,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 3),
                Text(
                  Formatters.compact(forks),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeetcodeSection extends StatelessWidget {
  const _LeetcodeSection({required this.result});
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final l = result.leetcode!;
    final theme = Theme.of(context);
    final total = (l.totalSolved <= 0
        ? (l.easySolved + l.mediumSolved + l.hardSolved)
        : l.totalSolved);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Solved',
                value: Formatters.integer(total),
                accent: DevIQColors.leetcode,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Ranking',
                value: l.ranking > 0 ? Formatters.compact(l.ranking) : '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Reputation',
                value: l.reputation > 0
                    ? Formatters.compact(l.reputation)
                    : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DevIQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Difficulty split',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              LanguageBars(
                entries: {
                  'Easy': l.easySolved.toDouble(),
                  'Medium': l.mediumSolved.toDouble(),
                  'Hard': l.hardSolved.toDouble(),
                },
                maxItems: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeforcesSection extends StatelessWidget {
  const _CodeforcesSection({required this.result});
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final c = result.codeforces!;
    final theme = Theme.of(context);
    final rc = DevIQColors.cfRankColor(c.rank);
    return Column(
      children: [
        DevIQCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.username,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RankBadge(c.rank),
                    const SizedBox(height: 8),
                    Text(
                      'Peak ${c.maxRating > 0 ? c.maxRating : '—'}${c.maxRank.isNotEmpty ? ' · ${c.maxRank}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${c.rating > 0 ? c.rating : '—'}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: rc,
                      fontSize: 34,
                    ),
                  ),
                  Text(
                    'RATING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Contests',
                value: '${c.contestsParticipated}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Problems',
                value: '${c.problemsSolved}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Contribution',
                value: '${c.contribution >= 0 ? '+' : ''}${c.contribution}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
