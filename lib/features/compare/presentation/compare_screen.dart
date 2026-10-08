import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../../data/models/analysis_models.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../app/providers/feature_controllers.dart';

/// Head-to-head comparison. Vertically stacked on mobile with a segmented
/// control, instead of squeezing two desktop cards side-by-side.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final _form = GlobalKey<FormState>();
  final _aGh = TextEditingController();
  final _aLc = TextEditingController();
  final _aCf = TextEditingController();
  final _bGh = TextEditingController();
  final _bLc = TextEditingController();
  final _bCf = TextEditingController();
  int _segment = 0; // 0 overview, 1 platform, 2 metrics

  @override
  void dispose() {
    for (final c in [_aGh, _aLc, _aCf, _bGh, _bLc, _bCf]) {
      c.dispose();
    }
    super.dispose();
  }

  void _run() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(compareProvider.notifier)
        .run(
          devA: (github: _aGh.text, leetcode: _aLc.text, codeforces: _aCf.text),
          devB: (github: _bGh.text, leetcode: _bLc.text, codeforces: _bCf.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(compareProvider);
    return DevIQPage(
      reserveNav: true,
      children: [
        const DevIQSectionLabel('HEAD-TO-HEAD'),
        const SizedBox(height: 10),
        Text(
          'Compare two\ndevelopers.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.02,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 18),
        Form(
          key: _form,
          child: Column(
            children: [
              _DevCard(
                title: 'Developer A',
                gh: _aGh,
                lc: _aLc,
                cf: _aCf,
                accent: DevIQColors.github,
              ),
              const SizedBox(height: 10),
              _DevCard(
                title: 'Developer B',
                gh: _bGh,
                lc: _bLc,
                cf: _bCf,
                accent: DevIQColors.codeforces,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DevIQButton(
          label: 'Compare',
          icon: Icons.compare_arrows,
          loading: state.status == CompareStatus.loading,
          onPressed: _run,
        ),
        const SizedBox(height: 16),
        switch (state.status) {
          CompareStatus.loading => const LoadingState(
            message: 'Fetching both developers…',
          ),
          CompareStatus.failure => ErrorState(
            message: state.error ?? 'Comparison failed.',
            onRetry: _run,
          ),
          CompareStatus.success => _CompareResults(
            a: state.a!,
            b: state.b!,
            segment: _segment,
            onSegment: (i) => setState(() => _segment = i),
          ),
          CompareStatus.idle => const EmptyState(
            icon: Icons.compare_arrows_outlined,
            title: 'No comparison yet',
            message: 'Fill in both developers above — even a single username per side works.',
          ),
        },
      ],
    );
  }
}

class _DevCard extends StatelessWidget {
  const _DevCard({
    required this.title,
    required this.gh,
    required this.lc,
    required this.cf,
    required this.accent,
  });

  final String title;
  final TextEditingController gh;
  final TextEditingController lc;
  final TextEditingController cf;
  final Color accent;

  @override
  Widget build(BuildContext context) => DevIQCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DevIQSectionLabel(title.toUpperCase(), accent: accent),
        const SizedBox(height: 10),
        DevIQTextField(
          controller: gh,
          hint: 'GitHub username',
          prefixIcon: Icons.hub_outlined,
          monospace: true,
          validator: (v) => Validators.username(v, required: false),
        ),
        const SizedBox(height: 10),
        DevIQTextField(
          controller: lc,
          hint: 'LeetCode username',
          prefixIcon: Icons.code_outlined,
          monospace: true,
          validator: (v) => Validators.username(v, required: false),
        ),
        const SizedBox(height: 10),
        DevIQTextField(
          controller: cf,
          hint: 'Codeforces handle',
          prefixIcon: Icons.emoji_events_outlined,
          monospace: true,
          validator: (v) => Validators.username(v, required: false),
        ),
      ],
    ),
  );
}

class _CompareResults extends StatelessWidget {
  const _CompareResults({
    required this.a,
    required this.b,
    required this.segment,
    required this.onSegment,
  });

  final AnalysisResult a;
  final AnalysisResult b;
  final int segment;
  final ValueChanged<int> onSegment;

  String _name(AnalysisResult r, String fallback) {
    if (r.githubUsername.isNotEmpty) return r.githubUsername;
    if (r.leetcodeUsername.isNotEmpty) return r.leetcodeUsername;
    if (r.codeforcesHandle.isNotEmpty) return r.codeforcesHandle;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sa = a.unifiedScore;
    final sb = b.unifiedScore;
    final winner = sa == sb ? -1 : (sa > sb ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == 2 ? 0 : 4,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      ['Overview', 'Platforms', 'Metrics'][i],
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: segment == i,
                    onSelected: (_) => onSegment(i),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DevIQCard(
          child: Column(
            children: [
              if (winner >= 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DevIQColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: DevIQColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '🏆 ${_name(winner == 0 ? a : b, '—')} wins by ${(sa - sb).abs().toStringAsFixed(1)} pts',
                    style: const TextStyle(
                      color: DevIQColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: ScoreRing(
                      score: sa,
                      diameter: 124,
                      label: _name(a, 'A'),
                    ),
                  ),
                  Flexible(
                    child: ScoreRing(
                      score: sb,
                      diameter: 124,
                      label: _name(b, 'B'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SegmentBody(segment: segment, a: a, b: b),
        const SizedBox(height: 4),
        Text(
          'Verdict: ${_name(a, 'A')} is ${ScoreUtils.verdict(sa).toLowerCase()} · ${_name(b, 'B')} is ${ScoreUtils.verdict(sb).toLowerCase()}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _SegmentBody extends StatelessWidget {
  const _SegmentBody({required this.segment, required this.a, required this.b});
  final int segment;
  final AnalysisResult a;
  final AnalysisResult b;

  String _name(AnalysisResult r, String fallback) {
    if (r.githubUsername.isNotEmpty) return r.githubUsername;
    if (r.leetcodeUsername.isNotEmpty) return r.leetcodeUsername;
    if (r.codeforcesHandle.isNotEmpty) return r.codeforcesHandle;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (segment == 1) {
      return _PlatformTable(a: a, b: b, na: _name(a, 'A'), nb: _name(b, 'B'));
    }
    if (segment == 2) {
      return _MetricTable(a: a, b: b, na: _name(a, 'A'), nb: _name(b, 'B'));
    }
    return _Overview(a: a, b: b, na: _name(a, 'A'), nb: _name(b, 'B'));
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.a,
    required this.b,
    required this.na,
    required this.nb,
  });
  final AnalysisResult a;
  final AnalysisResult b;
  final String na;
  final String nb;

  @override
  Widget build(BuildContext context) => DevIQCard(
    child: Column(
      children: [
        _VsRow(
          label: 'Unified score',
          va: a.unifiedScore.toStringAsFixed(1),
          vb: b.unifiedScore.toStringAsFixed(1),
          higherWins: true,
        ),
        _VsRow(
          label: 'GitHub score',
          va: a.githubScore?.toStringAsFixed(1) ?? '—',
          vb: b.githubScore?.toStringAsFixed(1) ?? '—',
          higherWins: true,
        ),
        _VsRow(
          label: 'LeetCode score',
          va: a.leetcodeScore?.toStringAsFixed(1) ?? '—',
          vb: b.leetcodeScore?.toStringAsFixed(1) ?? '—',
          higherWins: true,
        ),
        _VsRow(
          label: 'Codeforces score',
          va: a.codeforcesScore?.toStringAsFixed(1) ?? '—',
          vb: b.codeforcesScore?.toStringAsFixed(1) ?? '—',
          higherWins: true,
        ),
      ],
    ),
  );
}

class _PlatformTable extends StatelessWidget {
  const _PlatformTable({
    required this.a,
    required this.b,
    required this.na,
    required this.nb,
  });
  final AnalysisResult a;
  final AnalysisResult b;
  final String na;
  final String nb;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _PlatCard(
        title: 'GitHub',
        accent: DevIQColors.github,
        rows: [
          (
            'Stars',
            '${a.github?.totalStars ?? '—'}',
            '${b.github?.totalStars ?? '—'}',
          ),
          (
            'Repos',
            '${a.github?.totalProjects ?? '—'}',
            '${b.github?.totalProjects ?? '—'}',
          ),
          (
            'Top language',
            a.github?.mostUsedLanguage ?? '—',
            b.github?.mostUsedLanguage ?? '—',
          ),
        ],
      ),
      const SizedBox(height: 10),
      _PlatCard(
        title: 'LeetCode',
        accent: DevIQColors.leetcode,
        rows: [
          (
            'Solved',
            '${a.leetcode?.totalSolved ?? '—'}',
            '${b.leetcode?.totalSolved ?? '—'}',
          ),
          (
            'Hard',
            '${a.leetcode?.hardSolved ?? '—'}',
            '${b.leetcode?.hardSolved ?? '—'}',
          ),
          (
            'Ranking',
            '${a.leetcode?.ranking ?? '—'}',
            '${b.leetcode?.ranking ?? '—'}',
          ),
        ],
      ),
      const SizedBox(height: 10),
      _PlatCard(
        title: 'Codeforces',
        accent: DevIQColors.codeforces,
        rows: [
          (
            'Rating',
            '${a.codeforces?.rating ?? '—'}',
            '${b.codeforces?.rating ?? '—'}',
          ),
          ('Rank', a.codeforces?.rank ?? '—', b.codeforces?.rank ?? '—'),
          (
            'Contests',
            '${a.codeforces?.contestsParticipated ?? '—'}',
            '${b.codeforces?.contestsParticipated ?? '—'}',
          ),
        ],
      ),
    ],
  );
}

class _PlatCard extends StatelessWidget {
  const _PlatCard({
    required this.title,
    required this.accent,
    required this.rows,
  });
  final String title;
  final Color accent;
  final List<(String, String, String)> rows;

  @override
  Widget build(BuildContext context) => DevIQCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DevIQSectionLabel(title.toUpperCase(), accent: accent),
        const SizedBox(height: 6),
        for (final (l, va, vb) in rows)
          _VsRow(label: l, va: va, vb: vb, higherWins: false),
      ],
    ),
  );
}

class _MetricTable extends StatelessWidget {
  const _MetricTable({
    required this.a,
    required this.b,
    required this.na,
    required this.nb,
  });
  final AnalysisResult a;
  final AnalysisResult b;
  final String na;
  final String nb;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      (
        'GH stars',
        '${a.github?.totalStars ?? 0}',
        '${b.github?.totalStars ?? 0}',
      ),
      (
        'GH repos',
        '${a.github?.totalProjects ?? 0}',
        '${b.github?.totalProjects ?? 0}',
      ),
      (
        'LC solved',
        '${a.leetcode?.totalSolved ?? 0}',
        '${b.leetcode?.totalSolved ?? 0}',
      ),
      (
        'LC hard',
        '${a.leetcode?.hardSolved ?? 0}',
        '${b.leetcode?.hardSolved ?? 0}',
      ),
      (
        'CF rating',
        '${a.codeforces?.rating ?? 0}',
        '${b.codeforces?.rating ?? 0}',
      ),
      (
        'CF contests',
        '${a.codeforces?.contestsParticipated ?? 0}',
        '${b.codeforces?.contestsParticipated ?? 0}',
      ),
    ];
    return DevIQCard(
      child: Column(
        children: [
          for (final (l, va, vb) in rows)
            _VsRow(label: l, va: va, vb: vb, higherWins: false),
        ],
      ),
    );
  }
}

class _VsRow extends StatelessWidget {
  const _VsRow({
    required this.label,
    required this.va,
    required this.vb,
    required this.higherWins,
  });

  final String label;
  final String va;
  final String vb;
  final bool higherWins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final na = double.tryParse(va);
    final nb = double.tryParse(vb);
    final aWins = higherWins && na != null && nb != null && na > nb;
    final bWins = higherWins && na != null && nb != null && nb > na;
    TextStyle cell(bool win) => theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: win ? DevIQColors.success : theme.colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(va, textAlign: TextAlign.right, style: cell(aWins)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('·', style: TextStyle(color: DevIQColors.warning)),
          ),
          Expanded(
            flex: 2,
            child: Text(vb, textAlign: TextAlign.left, style: cell(bWins)),
          ),
        ],
      ),
    );
  }
}
