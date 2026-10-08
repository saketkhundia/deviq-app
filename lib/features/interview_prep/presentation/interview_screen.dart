import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/deviq_colors.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';
import '../../app/providers/feature_controllers.dart';

/// Interview prep: weak-category-driven LeetCode recommendations,
/// company filtering, solved + progress tracking.
class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  final _user = TextEditingController();
  String _tier = 'All';
  String _difficulty = 'All';
  bool _unsolvedOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(interviewProvider).problems.isEmpty) {
        ref.read(interviewProvider.notifier).loadCompany('google');
      }
    });
  }

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);
    final companies = PrepCompanies.all
        .where((c) => _tier == 'All' || c.tier == _tier)
        .toList();
    final problems = state.problems.where((p) {
      if (_difficulty != 'All' && p.difficulty != _difficulty) {
        return false;
      }
      if (_unsolvedOnly && state.solved.contains(p.slug)) return false;
      return true;
    }).toList();
    final solvedCount = state.problems
        .where((p) => state.solved.contains(p.slug))
        .length;

    return DevIQPage(
      reserveNav: false,
      children: [
        const DevIQSectionLabel('INTERVIEW PREP', accent: DevIQColors.warning),
        const SizedBox(height: 10),
        Text(
          'What Should You\nSolve Today?',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.02,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Get personalized LeetCode problem recommendations based on your weak categories.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        DevIQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DevIQTextField(
                controller: _user,
                label: 'LeetCode username',
                hint: 'for weak-category analysis',
                prefixIcon: Icons.code_outlined,
                monospace: true,
              ),
              const SizedBox(height: 6),
              Text(
                'Weak categories are derived from your difficulty split and company focus.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in ['All', 'FAANG+', 'Top Tier', 'Mid Tier'])
              ChoiceChip(
                label: Text(t, style: const TextStyle(fontSize: 11.5)),
                selected: _tier == t,
                onSelected: (_) => setState(() => _tier = t),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in companies)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DevIQPill(
                    label: c.name,
                    selected: state.company == c.slug,
                    onTap: () => notifier.loadCompany(c.slug),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state.problems.isNotEmpty)
          DevIQCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.problems.isEmpty
                              ? 0
                              : solvedCount / state.problems.length,
                          minHeight: 6,
                          backgroundColor: theme.dividerColor,
                          valueColor: const AlwaysStoppedAnimation(
                            DevIQColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$solvedCount / ${state.problems.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final d in ['All', 'Easy', 'Medium', 'Hard'])
              FilterChip(
                label: Text(d, style: const TextStyle(fontSize: 12)),
                selected: _difficulty == d,
                onSelected: (_) => setState(() => _difficulty = d),
              ),
            FilterChip(
              label: const Text('Unsolved', style: TextStyle(fontSize: 12)),
              selected: _unsolvedOnly,
              onSelected: (v) => setState(() => _unsolvedOnly = v),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (state.loading)
          const LoadingState(message: 'Loading problems…')
        else if (state.error != null)
          ErrorState(
            message: state.error!,
            onRetry: () => notifier.loadCompany(state.company),
          )
        else if (problems.isEmpty)
          const EmptyState(
            icon: Icons.work_outline,
            title: 'No problems match',
            message: 'Loosen the filters to see recommendations.',
          )
        else
          for (final p in problems.take(60))
            _ProblemCard(
              title: p.title,
              difficulty: p.difficulty,
              url: p.url,
              paidOnly: p.paidOnly,
              company: state.company,
              solved: state.solved.contains(p.slug),
              onToggle: (v) => notifier.toggleSolved(p.slug, v),
            ),
      ],
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.title,
    required this.difficulty,
    required this.url,
    required this.paidOnly,
    required this.company,
    required this.solved,
    required this.onToggle,
  });

  final String title;
  final String difficulty;
  final String url;
  final bool paidOnly;
  final String company;
  final bool solved;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DevIQCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: solved,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => onToggle(v ?? false),
            ),
            Expanded(
              child: InkWell(
                onTap: url.isEmpty
                    ? null
                    : () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: solved ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        DifficultyBadge(difficulty),
                        if (paidOnly) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_outline, size: 12),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
