import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/weak_categories.dart';
import '../../../data/models/ai_models.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../app/providers/feature_controllers.dart';

/// Interview prep mirroring the web reference: hero with username
/// analyzer, estimated weak-category cards, company-tag grid with brand
/// logos, and a selected-company panel (progress ring, search, difficulty
/// filters, trackable problem rows).
class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  final _user = TextEditingController();
  final _search = TextEditingController();
  String _tier = 'All';
  String _difficulty = 'All';

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
    _search.dispose();
    super.dispose();
  }

  void _analyze() {
    FocusScope.of(context).unfocus();
    ref.read(interviewProvider.notifier).analyzeWeak(_user.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(interviewProvider);
    final notifier = ref.read(interviewProvider.notifier);
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _user,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _analyze(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter your LeetCode username…',
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 108,
              child: DevIQSecondaryButton(
                label: state.analyzing ? '…' : 'Analyze',
                onPressed: state.analyzing ? null : _analyze,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'We\u2019ll analyze your problem-solving patterns to find your weakest areas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 20),
        const DevIQSectionLabel('YOUR WEAK CATEGORIES'),
        const SizedBox(height: 10),
        _WeakSection(state: state, onRetry: _analyze),
        const SizedBox(height: 24),
        const DevIQSectionLabel('COMPANY TAGS'),
        const SizedBox(height: 10),
        Text(
          'Company-Tagged Problems',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.01,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Browse problems frequently asked at top tech companies. Select a company below to view their question list and track your progress.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in ['All', 'FAANG+', 'Top Tier', 'Mid Tier'])
              _TierPill(
                label: t == 'All' ? 'All Companies' : t,
                selected: _tier == t,
                onTap: () => setState(() => _tier = t),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _CompanyGrid(
          tier: _tier,
          selected: state.company,
          onPick: (slug) => notifier.loadCompany(slug),
        ),
        const SizedBox(height: 12),
        _CompanyPanel(
          state: state,
          search: _search,
          difficulty: _difficulty,
          onDifficulty: (d) => setState(() => _difficulty = d),
          onToggle: notifier.toggleSolved,
          onRetry: () => notifier.loadCompany(state.company),
        ),
      ],
    );
  }
}

class _TierPill extends StatelessWidget {
  const _TierPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DevIQRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DevIQRadius.pill),
          border: Border.all(
            color: selected ? DevIQColors.github : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? DevIQColors.github : theme.colorScheme.secondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------- Weak categories ----------------

class _WeakSection extends StatelessWidget {
  const _WeakSection({required this.state, required this.onRetry});

  final InterviewState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.analyzing) {
      return const LoadingState(message: 'Analyzing patterns…');
    }
    if (state.weakError != null) {
      return ErrorState(message: state.weakError!, onRetry: onRetry);
    }
    if (state.weak.isEmpty) {
      return const EmptyState(
        icon: Icons.analytics_outlined,
        title: 'No weak categories yet',
        message: 'Enter your LeetCode username above and tap Analyze to estimate your weakest topics.',
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final twoCol = c.maxWidth >= 560;
        final cards = [for (final w in state.weak) _WeakCard(category: w)];
        if (!twoCol) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == cards.length - 1 ? 0 : 10,
                  ),
                  child: cards[i],
                ),
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 132,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) => cards[i],
        );
      },
    );
  }
}

class _WeakCard extends StatelessWidget {
  const _WeakCard({required this.category});

  final WeakCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = category.percent;
    final strong = pct >= 55;
    final color = strong ? DevIQColors.success : DevIQColors.warning;
    return DevIQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.solved} of ${category.total} solved',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              minHeight: 5,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodySmall,
              children: [
                TextSpan(
                  text: 'E: ${category.easy}  ',
                  style: const TextStyle(color: DevIQColors.success),
                ),
                TextSpan(
                  text: 'M: ${category.medium}  ',
                  style: const TextStyle(color: DevIQColors.warning),
                ),
                TextSpan(
                  text: 'H: ${category.hard}',
                  style: const TextStyle(color: DevIQColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Company grid ----------------

class _CompanyGrid extends StatelessWidget {
  const _CompanyGrid({
    required this.tier,
    required this.selected,
    required this.onPick,
  });

  final String tier;
  final String selected;
  final ValueChanged<String> onPick;

  String _tierKey(String t) => switch (t) {
    'FAANG+' => 'FAANG',
    'Top Tier' => 'Top',
    'Mid Tier' => 'Mid',
    _ => 'All',
  };

  @override
  Widget build(BuildContext context) {
    final key = _tierKey(tier);
    final companies = PrepCompanies.all
        .where((c) => key == 'All' || c.tier == key)
        .toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 130,
      ),
      itemCount: companies.length,
      itemBuilder: (context, i) {
        final c = companies[i];
        return _CompanyCard(
          company: c,
          selected: selected == c.slug,
          onTap: () => onPick(c.slug),
        );
      },
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.company,
    required this.selected,
    required this.onTap,
  });

  final PrepCompany company;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DevIQRadius.card),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(DevIQRadius.card),
          border: Border.all(
            color: selected ? DevIQColors.github : theme.dividerColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CompanyLogo(company: company, size: 44),
            const SizedBox(height: 10),
            Text(
              company.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              company.tier == 'FAANG'
                  ? 'FAANG'
                  : (company.tier == 'Top' ? 'Top' : 'Mid'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand logo tile: original logo asset, falling back to the bundled
/// brand glyph or a letter tile if the asset is missing.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key, required this.company, this.size = 44});

  final PrepCompany company;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: company.tile,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          company.logoAsset,
          width: size - 10,
          height: size - 10,
          fit: BoxFit.contain,
          errorBuilder: (context, _, _) => company.icon != null
              ? Icon(company.icon, size: size * 0.52, color: company.onTile)
              : Text(
                  company.letters,
                  style: TextStyle(
                    color: company.onTile,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.34,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------- Selected company panel ----------------

class _CompanyPanel extends StatelessWidget {
  const _CompanyPanel({
    required this.state,
    required this.search,
    required this.difficulty,
    required this.onDifficulty,
    required this.onToggle,
    required this.onRetry,
  });

  final InterviewState state;
  final TextEditingController search;
  final String difficulty;
  final ValueChanged<String> onDifficulty;
  final void Function(String slug, bool solved) onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final company = PrepCompanies.bySlug(state.company);
    final solvedCount = state.problems
        .where((p) => state.solved.contains(p.slug))
        .length;
    final total = state.problems.length;
    final pct = total == 0 ? 0.0 : solvedCount / total;
    final q = search.text.trim().toLowerCase();
    final visible = state.problems.where((p) {
      if (difficulty != 'All' && p.difficulty != difficulty) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.slug.toLowerCase().contains(q);
    }).toList();
    final easy = state.problems.where((p) => p.difficulty == 'Easy').length;
    final medium = state.problems.where((p) => p.difficulty == 'Medium').length;
    final hard = state.problems.where((p) => p.difficulty == 'Hard').length;
    final easySolved = state.problems
        .where((p) => p.difficulty == 'Easy' && state.solved.contains(p.slug))
        .length;
    final medSolved = state.problems
        .where((p) => p.difficulty == 'Medium' && state.solved.contains(p.slug))
        .length;
    final hardSolved = state.problems
        .where((p) => p.difficulty == 'Hard' && state.solved.contains(p.slug))
        .length;
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CompanyLogo(company: company, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$total problems · $solvedCount solved',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      Text(
                        '(${(pct * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          color: DevIQColors.github,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _ProgressRing(progress: pct),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: search,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search problems or topics…',
                          prefixIcon: Icon(Icons.search, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DiffPill(
                        key: const ValueKey('diff-all'),
                        label: 'All ($total)',
                        selected: difficulty == 'All',
                        onTap: () => onDifficulty('All'),
                      ),
                      for (final d in ['Easy', 'Medium', 'Hard'])
                        _DiffPill(
                          key: ValueKey('diff-$d'),
                          label: d,
                          selected: difficulty == d,
                          onTap: () => onDifficulty(d),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  const TextSpan(
                    text: 'Easy: ',
                    style: TextStyle(color: DevIQColors.success),
                  ),
                  TextSpan(
                    text: '$easySolved/$easy   ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text: 'Medium: ',
                    style: TextStyle(color: DevIQColors.warning),
                  ),
                  TextSpan(
                    text: '$medSolved/$medium   ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text: 'Hard: ',
                    style: TextStyle(color: DevIQColors.error),
                  ),
                  TextSpan(
                    text: '$hardSolved/$hard',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          if (state.loading)
            const LoadingState(message: 'Loading problems…')
          else if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorState(message: state.error!, onRetry: onRetry),
            )
          else if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: EmptyState(
                icon: Icons.work_outline,
                title: 'No problems match',
                message: 'Loosen the search or difficulty filter.',
              ),
            )
          else
            for (var i = 0; i < visible.length; i++) ...[
              _ProblemRow(
                problem: visible[i],
                solved: state.solved.contains(visible[i].slug),
                onToggle: (v) => onToggle(visible[i].slug, v),
                last: i == visible.length - 1,
              ),
              if (i != visible.length - 1)
                Divider(height: 1, color: theme.dividerColor),
            ],
        ],
      ),
    );
  }
}

class _DiffPill extends StatelessWidget {
  const _DiffPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DevIQRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DevIQRadius.button),
            border: Border.all(
              color: selected ? DevIQColors.github : theme.dividerColor,
            ),
            color: selected
                ? DevIQColors.github.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? DevIQColors.github
                  : theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: progress.clamp(0, 1),
          color: DevIQColors.success,
          track: theme.dividerColor,
        ),
        child: Center(
          child: Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 3;
    final bg = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, r, bg);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

class _ProblemRow extends StatelessWidget {
  const _ProblemRow({
    required this.problem,
    required this.solved,
    required this.onToggle,
    required this.last,
  });

  final CompanyProblem problem;
  final bool solved;
  final ValueChanged<bool> onToggle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: problem.url.isEmpty
          ? null
          : () => launchUrl(
              Uri.parse(problem.url),
              mode: LaunchMode.externalApplication,
            ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, last ? 16 : 12),
        child: Row(
          children: [
            _CheckBox(value: solved, onChanged: onToggle),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${problem.id}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          problem.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: solved
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (problem.paidOnly) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DevIQColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: DevIQColors.warning.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        'Premium',
                        style: TextStyle(
                          color: DevIQColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            DifficultyBadge(problem.difficulty),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? DevIQColors.success : theme.colorScheme.secondary,
            width: 1.4,
          ),
          color: value
              ? DevIQColors.success.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: value
            ? const Icon(Icons.check, size: 15, color: DevIQColors.success)
            : null,
      ),
    );
  }
}
