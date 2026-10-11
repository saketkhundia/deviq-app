import 'package:flutter/material.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/role_fit.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/analysis_models.dart';
import '../../../../shared/widgets/signal.dart';
import 'liquid_glass.dart';

/// 03 / Skill profile — rebuilt from scratch in liquid glass.
///
/// Every bar explains a real metric computed from the user's actual
/// data (session result preferred, last persisted analysis otherwise),
/// rendered as luminous glass micro-bars on one frosted panel.
/// DevIQ-owned synthesis uses signal green; platform axes keep their
/// semantic colors. No data → the section defers to onboarding copy.
class SkillProfile extends StatelessWidget {
  const SkillProfile({super.key, required this.result, required this.last});

  final AnalysisResult? result;
  final HistoryRecord? last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final rows = _rows(dark);

    if (rows.isEmpty) {
      return const GlassSectionHeader(
        index: '03',
        title: 'Skill profile',
        caption:
            'Engineering activity, problem solving and competitive programming break down here once you have a scored profile.',
      );
    }

    final best = result != null ? _bestRole(result!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSectionHeader(
          index: '03',
          title: 'Skill profile',
          caption: result != null
              ? 'Computed from your live analysis.'
              : 'Computed from your last analysis ${Formatters.date(last!.date)}.',
        ),
        const SizedBox(height: 14),
        LiquidGlass(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _SkillRow(
                  row: rows[i],
                  last: i == rows.length - 1 && best == null,
                ),
              if (best != null) ...[
                const SizedBox(height: 2),
                _RoleFitLine(role: best.role, evidence: best.evidence),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<_Skill> _rows(bool dark) {
    if (result != null && result!.hasData) {
      final r = result!;
      final out = <_Skill>[];
      if (r.github != null) {
        final g = r.github!;
        out.add(_Skill(
          color: DevIQColors.github,
          label: 'Engineering activity',
          evidence:
              '${g.totalProjects} repos · ${Formatters.compact(g.totalStars)} stars${g.mostUsedLanguage.isEmpty ? '' : ' · ${g.mostUsedLanguage}'}',
          value: r.githubScore ?? 0,
        ));
      }
      if (r.leetcode != null) {
        final l = r.leetcode!;
        out.add(_Skill(
          color: DevIQColors.leetcode,
          label: 'Problem solving',
          evidence:
              '${l.totalSolved} solved · ${l.easySolved}E ${l.mediumSolved}M ${l.hardSolved}H',
          value: r.leetcodeScore ?? 0,
        ));
      }
      if (r.codeforces != null) {
        final c = r.codeforces!;
        out.add(_Skill(
          color: DevIQColors.codeforces,
          label: 'Competitive programming',
          evidence:
              '${c.rating} · ${c.rank.isEmpty ? 'Unrated' : c.rank} · ${c.contestsParticipated} contests',
          value: r.codeforcesScore ?? 0,
        ));
      }
      final contrib = r.contributions;
      if (contrib != null && contrib.days.isNotEmpty) {
        final denom = contrib.longestStreak <= 0
            ? 1
            : contrib.longestStreak;
        out.add(_Skill(
          color: DevIQColors.signalFor(dark),
          label: 'Consistency',
          evidence:
              '${contrib.currentStreak}d streak · ${Formatters.compact(contrib.total)} contributions',
          value: (contrib.currentStreak / denom * 100).clamp(0, 100),
          percentLabel: '${contrib.currentStreak}d',
        ));
      }
      return out;
    }
    if (last != null) {
      final h = last!;
      return [
        _Skill(
          color: DevIQColors.github,
          label: 'Engineering activity',
          evidence: '${h.repos} repos · ${h.stars} stars',
          value: ScoreUtils.githubScore(
            repos: h.repos,
            stars: h.stars,
            languages: h.language.isEmpty ? 0 : 1,
          ),
        ),
        _Skill(
          color: DevIQColors.leetcode,
          label: 'Problem solving',
          evidence: '${h.lcSolved} solved · ${h.lcHard} hard',
          value: ScoreUtils.leetcodeScore(
            solved: h.lcSolved,
            hard: h.lcHard,
          ),
        ),
        _Skill(
          color: DevIQColors.codeforces,
          label: 'Competitive programming',
          evidence:
              '${h.cfRating} · ${h.cfRank.isEmpty ? 'Unrated' : h.cfRank}',
          value: ScoreUtils.codeforcesScore(
            rating: h.cfRating,
            contests: h.cfContests,
            solved: h.cfProblems,
          ),
        ),
      ];
    }
    return const [];
  }

  RoleFit? _bestRole(AnalysisResult r) {
    final fits = estimateRoleFit(r);
    return fits.isEmpty ? null : fits.first;
  }
}

class _Skill {
  const _Skill({
    required this.color,
    required this.label,
    required this.evidence,
    required this.value,
    this.percentLabel,
  });

  final Color color;
  final String label;
  final String evidence;
  final double value;
  final String? percentLabel;
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.row, required this.last});
  final _Skill row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(
                  color: LiquidGlassTokens.edge(
                    theme.brightness == Brightness.dark,
                  ),
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: row.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: row.color.withValues(alpha: 0.7),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                row.percentLabel ?? row.value.toStringAsFixed(0),
                style: SignalType.tabular(
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 17),
            child: Text(
              row.evidence,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SignalType.mono(context, size: 11),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 17),
            child: GlassBar(value: row.value / 100, color: row.color, height: 5),
          ),
        ],
      ),
    );
  }
}

/// Best role match on one quiet luminous row, linking the skill
/// profile to career direction.
class _RoleFitLine extends StatelessWidget {
  const _RoleFitLine({required this.role, required this.evidence});
  final String role;
  final List<String> evidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.work_outline,
            size: 16,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Best fit: ',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                  TextSpan(
                    text: role,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (evidence.isNotEmpty)
                    TextSpan(
                      text: ' · ${evidence.join(' · ')}',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
