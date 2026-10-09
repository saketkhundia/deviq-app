import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/role_fit.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import 'analyze_controller.dart';
import 'insights_controller.dart';
import 'widgets/activity_section.dart';
import 'widgets/ai_insights_panel.dart';
import 'widgets/github_insights.dart';
import 'widgets/platform_cards.dart';
import 'widgets/repo_browser.dart';
import 'widgets/report_card.dart';
import 'widgets/role_section.dart';
import 'widgets/section_nav.dart';
import 'widgets/share_card.dart';
import 'widgets/username_form.dart';

/// Analyze page assembly: intro → username form → section nav → keyed
/// report sections. Section taps smooth-scroll with an offset so the
/// fixed shell header never covers headings.
class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  final _scroll = ScrollController();
  final _keys = {
    'score': GlobalKey(),
    'platforms': GlobalKey(),
    'ai': GlobalKey(),
    'activity': GlobalKey(),
    'role': GlobalKey(),
    'repos': GlobalKey(),
  };

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _run(String github, String leetcode, String codeforces) {
    ref.read(insightsProvider.notifier).reset();
    ref
        .read(analyzeProvider.notifier)
        .run(github: github, leetcode: leetcode, codeforces: codeforces);
  }

  void _goTo(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx == null) return;
    // alignment 0.12 leaves room for the fixed shell header + status bar.
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(analyzeProvider);
    final loading = state.status == AnalyzeStatus.loading;
    return DevIQPage(
      reserveNav: true,
      controller: _scroll,
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
        UsernameForm(loading: loading, onRun: _run),
        const SizedBox(height: 16),
        if (loading)
          const Column(
            children: [
              SkeletonCard(height: 220),
              SizedBox(height: 10),
              SkeletonCard(height: 160),
            ],
          )
        else if (state.status == AnalyzeStatus.failure)
          ErrorState(
            message: state.error ?? 'Analysis failed.',
            onRetry: () => ref.read(analyzeProvider.notifier).reset(),
          )
        else if (state.status == AnalyzeStatus.success)
          _Report(state: state, keys: _keys, onSection: _goTo)
        else
          const EmptyState(
            icon: Icons.analytics_outlined,
            title: 'No analysis yet',
            message: 'Enter at least one username above and run an analysis to see your unified DevIQ score.',
          ),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({
    required this.state,
    required this.keys,
    required this.onSection,
  });

  final AnalyzeState state;
  final Map<String, GlobalKey> keys;
  final void Function(String id) onSection;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final fits = estimateRoleFit(result);
    Widget section(String id, Widget child) => Column(
      key: keys[id],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [child],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionNav(onSelect: onSection),
        const SizedBox(height: 14),
        if (state.failedPlatforms.isNotEmpty)
          _PartialWarning(failed: state.failedPlatforms),
        section('score', AnalysisReportCard(result: result)),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DevIQSectionLabel('DEVELOPER CARD'),
            const SizedBox(height: 10),
            ShareActions(result: result),
            const SizedBox(height: 10),
            DeveloperShareCard(result: result),
          ],
        ),
        if (result.github != null ||
            result.leetcode != null ||
            result.codeforces != null) ...[
          const SizedBox(height: 20),
          section(
            'platforms',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DevIQSectionLabel('PLATFORMS'),
                const SizedBox(height: 10),
                if (result.github != null) ...[
                  GithubPlatformCard(result: result),
                  const SizedBox(height: 14),
                ],
                if (result.leetcode != null) ...[
                  LeetcodePlatformCard(result: result),
                  const SizedBox(height: 14),
                ],
                if (result.codeforces != null)
                  CodeforcesPlatformCard(result: result),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        section(
          'ai',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DevIQSectionLabel('AI INSIGHTS'),
              const SizedBox(height: 10),
              AiInsightsPanel(result: result),
            ],
          ),
        ),
        if (result.contributions != null &&
            result.contributions!.days.isNotEmpty) ...[
          const SizedBox(height: 20),
          section(
            'activity',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DevIQSectionLabel('ACTIVITY'),
                const SizedBox(height: 10),
                ActivitySection(data: result.contributions!),
              ],
            ),
          ),
        ],
        if (result.github != null) ...[
          const SizedBox(height: 20),
          GithubInsights(github: result.github!),
        ],
        const SizedBox(height: 20),
        section(
          'role',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DevIQSectionLabel('WHICH ROLE FITS YOU BEST?'),
              const SizedBox(height: 10),
              RoleSection(fits: fits),
            ],
          ),
        ),
        if (result.github != null &&
            result.github!.repositories.isNotEmpty) ...[
          const SizedBox(height: 20),
          section(
            'repos',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DevIQSectionLabel('REPOSITORIES'),
                const SizedBox(height: 10),
                RepositoryBrowser(github: result.github!),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PartialWarning extends StatelessWidget {
  const _PartialWarning({required this.failed});

  final List<String> failed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Partial data: ${failed.join(', ')} couldn\u2019t be reached. Showing the rest.',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
