import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../../data/models/analysis_models.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/widgets/platform_icons.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../app/providers/feature_controllers.dart';

/// Head-to-head comparison mirroring the web reference: stacked
/// developer cards on mobile, white Compare button, then a single
/// result card with the face-off, win pills and dual-bar metric rows.
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

  @override
  void dispose() {
    for (final c in [_aGh, _aLc, _aCf, _bGh, _bLc, _bCf]) {
      c.dispose();
    }
    super.dispose();
  }

  void _run() {
    if (ref.read(compareProvider).status == CompareStatus.loading) return;
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
      reserveNav: false,
      children: [
        const DevIQSectionLabel('HEAD-TO-HEAD'),
        const SizedBox(height: 10),
        Text(
          'Compare two developers.',
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
              _DevCard(title: 'Developer A', gh: _aGh, lc: _aLc, cf: _aCf),
              const SizedBox(height: 10),
              _DevCard(title: 'Developer B', gh: _bGh, lc: _bLc, cf: _bCf),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DevIQButton(
          label: 'Compare',
          loading: state.status == CompareStatus.loading,
          onPressed: _run,
        ),
        const SizedBox(height: 16),
        switch (state.status) {
          CompareStatus.loading => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Fetching data…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
          CompareStatus.failure => ErrorState(
            message: state.error ?? 'Comparison failed.',
            onRetry: _run,
          ),
          CompareStatus.success => _CompareResults(a: state.a!, b: state.b!),
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

/// Developer input card: header band with divider, brand mini-labels
/// above plain username fields.
class _DevCard extends StatelessWidget {
  const _DevCard({
    required this.title,
    required this.gh,
    required this.lc,
    required this.cf,
  });

  final String title;
  final TextEditingController gh;
  final TextEditingController lc;
  final TextEditingController cf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandLabel(platform: DevPlatform.github),
                const SizedBox(height: 6),
                DevIQTextField(
                  controller: gh,
                  hint: 'username',
                  monospace: true,
                  validator: (v) => Validators.username(v, required: false),
                ),
                const SizedBox(height: 12),
                _BrandLabel(platform: DevPlatform.leetcode),
                const SizedBox(height: 6),
                DevIQTextField(
                  controller: lc,
                  hint: 'username',
                  monospace: true,
                  validator: (v) => Validators.username(v, required: false),
                ),
                const SizedBox(height: 12),
                _BrandLabel(platform: DevPlatform.codeforces),
                const SizedBox(height: 6),
                DevIQTextField(
                  controller: cf,
                  hint: 'username',
                  monospace: true,
                  validator: (v) => Validators.username(v, required: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLabel extends StatelessWidget {
  const _BrandLabel({required this.platform});

  final DevPlatform platform;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PlatformIcons.of(platform),
          size: 12,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 6),
        Text(
          PlatformIcons.labelOf(platform).toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CompareResults extends StatelessWidget {
  const _CompareResults({required this.a, required this.b});

  final AnalysisResult a;
  final AnalysisResult b;

  static const _aColor = DevIQColors.github;
  static const _bColor = DevIQColors.codeforces;

  String _name(AnalysisResult r, String fallback) {
    if (r.githubUsername.isNotEmpty) return r.githubUsername;
    if (r.leetcodeUsername.isNotEmpty) return r.leetcodeUsername;
    if (r.codeforcesHandle.isNotEmpty) return r.codeforcesHandle;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final na = _name(a, 'A');
    final nb = _name(b, 'B');
    final sa = a.unifiedScore;
    final sb = b.unifiedScore;
    final rows = _rows();
    var winsA = 0;
    var winsB = 0;
    for (final r in rows) {
      if (r.a != null && r.b != null) {
        if (r.a! > r.b!) {
          winsA++;
        } else if (r.b! > r.a!) {
          winsB++;
        }
      } else if (r.a != null) {
        winsA++;
      } else if (r.b != null) {
        winsB++;
      }
    }
    final tied = sa == sb;
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tied
                  ? 'Dead even at ${sa.toStringAsFixed(1)}'
                  : '${sa > sb ? na : nb} leads by ${(sa - sb).abs().toStringAsFixed(1)} pts',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FaceOffSide(name: na, nameColor: _aColor, score: sa),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: Text(
                    'VS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: _FaceOffSide(name: nb, nameColor: _bColor, score: sb),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WinPill(
                  text: '$na: $winsA win${winsA == 1 ? '' : 's'}',
                  color: _aColor,
                ),
                _WinPill(
                  text: '$nb: $winsB win${winsB == 1 ? '' : 's'}',
                  color: _bColor,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          for (var i = 0; i < rows.length; i++)
            _MetricRow(row: rows[i], last: i == rows.length - 1),
        ],
      ),
    );
  }

  List<_Row> _rows() {
    return [
      _Row(
        label: 'Dev Score',
        a: a.unifiedScore,
        b: b.unifiedScore,
        fmt: (v) => v.toStringAsFixed(1),
      ),
      _Row(
        label: 'Repos',
        a: a.github?.totalProjects,
        b: b.github?.totalProjects,
        fmt: (v) => Formatters.integer(v),
      ),
      _Row(
        label: 'Stars',
        a: a.github?.totalStars,
        b: b.github?.totalStars,
        fmt: (v) => Formatters.integer(v),
      ),
      _Row(
        label: 'LC Solved',
        a: _lcSolved(a),
        b: _lcSolved(b),
        fmt: (v) => Formatters.integer(v),
      ),
      _Row(
        label: 'LC Hard',
        a: a.leetcode?.hardSolved,
        b: b.leetcode?.hardSolved,
        fmt: (v) => Formatters.integer(v),
      ),
      _Row(
        label: 'CF Rating',
        a: _cfRating(a),
        b: _cfRating(b),
        fmt: (v) => Formatters.integer(v),
      ),
      _Row(
        label: 'CF Problems',
        a: a.codeforces?.problemsSolved,
        b: b.codeforces?.problemsSolved,
        fmt: (v) => Formatters.integer(v),
      ),
    ];
  }

  int? _lcSolved(AnalysisResult r) {
    final lc = r.leetcode;
    if (lc == null) return null;
    final total = lc.totalSolved > 0
        ? lc.totalSolved
        : lc.easySolved + lc.mediumSolved + lc.hardSolved;
    return total;
  }

  int? _cfRating(AnalysisResult r) {
    final cf = r.codeforces;
    if (cf == null || cf.rating <= 0) return null;
    return cf.rating;
  }
}

class _Row {
  const _Row({
    required this.label,
    required this.a,
    required this.b,
    required this.fmt,
  });

  final String label;
  final num? a;
  final num? b;
  final String Function(num v) fmt;
}

class _FaceOffSide extends StatelessWidget {
  const _FaceOffSide({
    required this.name,
    required this.nameColor,
    required this.score,
  });

  final String name;
  final Color nameColor;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: nameColor,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        ScoreRing(
          score: score,
          diameter: 110,
          duration: const Duration(milliseconds: 1100),
        ),
        const SizedBox(height: 8),
        _VerdictChip(score: score),
      ],
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = DevIQColors.scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        ScoreUtils.verdict(score),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _WinPill extends StatelessWidget {
  const _WinPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

/// Metric row: muted label, "A ← vs B" values, dual proportional bars
/// relative to the row max. Missing sides render "—" with no bars.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.row, required this.last});

  final _Row row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aWins = row.a != null && (row.b == null || row.a! > row.b!);
    final bWins = row.b != null && (row.a == null || row.b! > row.a!);
    final max = [row.a ?? 0, row.b ?? 0].fold<num>(0, (m, v) => v > m ? v : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    if (row.a != null)
                      TextSpan(
                        text: '${row.fmt(row.a!)}${aWins ? ' ←' : ''}',
                        style: TextStyle(
                          color: aWins
                              ? _CompareResults._aColor
                              : theme.colorScheme.onSurface,
                        ),
                      )
                    else
                      TextSpan(
                        text: '—',
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                    TextSpan(
                      text: '  vs  ',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                    if (row.b != null)
                      TextSpan(
                        text: '${bWins ? '→ ' : ''}${row.fmt(row.b!)}',
                        style: TextStyle(
                          color: bWins
                              ? _CompareResults._bColor
                              : theme.colorScheme.onSurface,
                        ),
                      )
                    else
                      TextSpan(
                        text: '—',
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (max > 0) ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ((row.a ?? 0) / max).clamp(0, 1).toDouble(),
                minHeight: 3,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.4),
                valueColor: const AlwaysStoppedAnimation(
                  _CompareResults._aColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ((row.b ?? 0) / max).clamp(0, 1).toDouble(),
                minHeight: 3,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.4),
                valueColor: const AlwaysStoppedAnimation(
                  _CompareResults._bColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
