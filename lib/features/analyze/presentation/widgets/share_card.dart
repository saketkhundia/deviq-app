import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/analysis_models.dart';
import '../../../../shared/widgets/deviq_widgets.dart';
import '../../../../shared/widgets/score_ring.dart';

/// Action row shown above the developer card (Share LinkedIn / Copy link /
/// Download), mirroring the web reference.
class ShareActions extends StatelessWidget {
  const ShareActions({super.key, required this.result});

  final AnalysisResult result;

  String _link() {
    final u = result.githubUsername.isNotEmpty
        ? result.githubUsername
        : (result.leetcodeUsername.isNotEmpty
              ? result.leetcodeUsername
              : result.codeforcesHandle);
    return 'https://www.deviq.online/?profile=$u';
  }

  Future<void> _linkedIn(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(_link())}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open LinkedIn.')));
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'My DevIQ score: ${result.unifiedScore.toStringAsFixed(0)}/100 — ${_link()}',
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Report link copied.')));
    }
  }

  Future<void> _download(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/deviq-report-$stamp.md');
      await file.writeAsString(buildReportMarkdown(result));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Future<void> _share(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'My DevIQ score: ${result.unifiedScore.toStringAsFixed(0)}/100 — ${_link()}',
        subject: 'My DevIQ developer report',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      _GridAction(
        icon: Icons.share_outlined,
        label: 'Share',
        onTap: () => _share(context),
      ),
      _GridAction(
        icon: Icons.business,
        label: 'Share LinkedIn',
        onTap: () => _linkedIn(context),
      ),
      _GridAction(
        icon: Icons.link_outlined,
        label: 'Copy link',
        onTap: () => _copy(context),
      ),
      _GridAction(
        icon: Icons.download_outlined,
        label: 'Download',
        onTap: () => _download(context),
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 46,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => actions[i],
    );
  }
}

/// Equal-width action button for the 2×2 grid (labels ellipsize instead
/// of wrapping the grid unevenly).
class _GridAction extends StatelessWidget {
  const _GridAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.dividerColor),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DevIQRadius.button),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shareable developer summary card: green top accent, report label +
/// title + classification left with the ring right, six metric tiles,
/// data summary and a brand/date footer.
class DeveloperShareCard extends StatelessWidget {
  const DeveloperShareCard({super.key, required this.result});

  final AnalysisResult result;

  String _title() {
    final parts = [
      result.githubUsername,
      result.leetcodeUsername,
      result.codeforcesHandle,
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = result.unifiedScore;
    final g = result.github;
    final lc = result.leetcode;
    final cf = result.codeforces;
    final solved = lc == null
        ? 0
        : (lc.totalSolved > 0
              ? lc.totalSolved
              : lc.easySolved + lc.mediumSolved + lc.hardSolved);
    final tiles = <({String label, String value})>[
      (label: 'REPOS', value: '${g?.totalProjects ?? 0}'),
      (label: 'SOLVED', value: Formatters.integer(solved)),
      (
        label: 'CF RATING',
        value: (cf != null && cf.rating > 0) ? '${cf.rating}' : '—',
      ),
      (label: 'STARS', value: Formatters.integer(g?.totalStars ?? 0)),
      (label: 'HARD', value: Formatters.integer(lc?.hardSolved ?? 0)),
      (
        label: 'LANGUAGE',
        value: (g?.mostUsedLanguage ?? '').isEmpty ? '—' : g!.mostUsedLanguage,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: DevIQColors.success.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
      ),
      child: DevIQCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVIQ REPORT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _title(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.01,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ClassificationBadge(score: score),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ScoreRing(
                      score: score,
                      diameter: 108,
                      duration: const Duration(milliseconds: 900),
                      color: DevIQColors.success,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dev Score',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 64,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, i) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tiles[i].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      tiles[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _summary(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'DevIQ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _date(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _summary() {
    final bits = <String>[];
    final g = result.github;
    if (g != null) {
      bits.add(
        '${Formatters.integer(g.totalProjects)} repos · ${Formatters.integer(g.totalStars)} stars',
      );
    }
    final lc = result.leetcode;
    if (lc != null) {
      final solved = lc.totalSolved > 0
          ? lc.totalSolved
          : lc.easySolved + lc.mediumSolved + lc.hardSolved;
      bits.add('${Formatters.integer(solved)} LeetCode solves');
    }
    final cf = result.codeforces;
    if (cf != null && cf.rating > 0) {
      bits.add(
        'Codeforces ${cf.rating}'
        '${cf.rank.isNotEmpty ? ' (${cf.rank})' : ''}',
      );
    }
    if (bits.isEmpty) return 'Unified score from connected platforms.';
    return '${bits.join(' · ')}.';
  }

  String _date() {
    final d = result.analyzedAt;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _ClassificationBadge extends StatelessWidget {
  const _ClassificationBadge({required this.score});

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

/// Builds the downloadable Markdown report. Pure — unit tested.
String buildReportMarkdown(AnalysisResult r) {
  final b = StringBuffer()
    ..writeln('# DevIQ Developer Report')
    ..writeln()
    ..writeln('Date: ${r.analyzedAt.toIso8601String()}')
    ..writeln(
      'Profile: ${[r.githubUsername, r.leetcodeUsername, r.codeforcesHandle].where((e) => e.isNotEmpty).join(' / ')}',
    )
    ..writeln(
      'Unified score: ${r.unifiedScore.toStringAsFixed(1)}/100 '
      '(${ScoreUtils.verdict(r.unifiedScore)})',
    )
    ..writeln();
  final g = r.github;
  if (g != null) {
    b
      ..writeln('## GitHub (${g.username})')
      ..writeln('- Repositories: ${g.totalProjects}')
      ..writeln('- Stars: ${g.totalStars}')
      ..writeln('- Forks: ${g.totalForks}')
      ..writeln('- Top language: ${g.mostUsedLanguage}')
      ..writeln();
  }
  final lc = r.leetcode;
  if (lc != null) {
    b
      ..writeln('## LeetCode (${lc.username})')
      ..writeln('- Solved: ${lc.totalSolved}')
      ..writeln(
        '- Easy/Medium/Hard: ${lc.easySolved}/${lc.mediumSolved}/${lc.hardSolved}',
      )
      ..writeln('- Ranking: ${lc.ranking}')
      ..writeln();
  }
  final cf = r.codeforces;
  if (cf != null) {
    b
      ..writeln('## Codeforces (${cf.username})')
      ..writeln('- Rating: ${cf.rating} (peak ${cf.maxRating})')
      ..writeln('- Rank: ${cf.rank}')
      ..writeln('- Contests: ${cf.contestsParticipated}')
      ..writeln();
  }
  b.writeln('Generated by DevIQ · https://www.deviq.online');
  return b.toString();
}
