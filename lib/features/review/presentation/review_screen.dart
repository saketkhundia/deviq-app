import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/deviq_colors.dart';
import '../../../data/models/ai_models.dart';
import '../../../shared/widgets/code_editor.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';
import '../../app/providers/feature_controllers.dart';

const _sampleCode = '''def fibonacci(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

print(fibonacci(10))''';

/// AI code review: language + editor + structured senior-level results.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _code = TextEditingController();
  String _language = 'python';
  bool _optimizing = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _review() {
    FocusScope.of(context).unfocus();
    ref
        .read(reviewProvider.notifier)
        .review(code: _code.text, language: _language);
  }

  Future<void> _optimize() async {
    setState(() => _optimizing = true);
    await ref
        .read(reviewProvider.notifier)
        .optimize(code: _code.text, language: _language);
    if (mounted) setState(() => _optimizing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(reviewProvider);
    return DevIQPage(
      reserveNav: false,
      children: [
        const DevIQSectionLabel('AI CODE REVIEW', accent: DevIQColors.ai),
        const SizedBox(height: 10),
        Text(
          'Paste code.\nGet a senior-level review.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.02,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final l in PlaygroundLanguages.all)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DevIQPill(
                    label: l.label,
                    selected: l.id == _language,
                    onTap: () => setState(() => _language = l.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CodeEditor(
          controller: _code,
          language:
              PlaygroundLanguages.byId(_language).highlightId ?? 'plaintext',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DevIQSecondaryButton(
                label: 'Try sample',
                onPressed: () => setState(() => _code.text = _sampleCode),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DevIQSecondaryButton(
                label: 'Clear',
                onPressed: () => setState(_code.clear),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DevIQButton(
          label: 'Review Code',
          icon: Icons.auto_awesome_outlined,
          loading: state.status == ReviewStatus.loading,
          onPressed: _review,
        ),
        const SizedBox(height: 16),
        switch (state.status) {
          ReviewStatus.loading => const LoadingState(
            message: 'Reviewing your code…',
          ),
          ReviewStatus.failure => ErrorState(
            message: state.error ?? 'Review failed.',
            onRetry: _review,
          ),
          ReviewStatus.success => _ReviewResults(
            result: state.result!,
            optimized: state.optimized,
            optimizing: _optimizing,
            language: _language,
            onOptimize: _optimize,
          ),
          ReviewStatus.idle => const EmptyState(
            icon: Icons.rate_review_outlined,
            title: 'No review yet',
            message:
                'Paste code above — or try the sample — then run a review.',
          ),
        },
      ],
    );
  }
}

class _ReviewResults extends StatelessWidget {
  const _ReviewResults({
    required this.result,
    required this.optimized,
    required this.optimizing,
    required this.language,
    required this.onOptimize,
  });

  final CodeReviewResult result;
  final String? optimized;
  final bool optimizing;
  final String language;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DevIQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Summary',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DevIQColors.scoreColor(result.score)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      result.score.toStringAsFixed(0),
                      style: TextStyle(
                        color: DevIQColors.scoreColor(result.score),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.summary.isEmpty
                    ? 'Review complete. See findings below.'
                    : result.summary,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
              if (result.timeComplexity.isNotEmpty ||
                  result.spaceComplexity.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (result.timeComplexity.isNotEmpty)
                      Chip(label: Text('Time: ${result.timeComplexity}')),
                    if (result.spaceComplexity.isNotEmpty)
                      Chip(label: Text('Space: ${result.spaceComplexity}')),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (result.bugs.isNotEmpty) ...[
          const SizedBox(height: 10),
          _IssueGroup(
            title: 'Bugs',
            issues: result.bugs,
            color: DevIQColors.error,
          ),
        ],
        if (result.security.isNotEmpty) ...[
          const SizedBox(height: 10),
          _IssueGroup(
            title: 'Security',
            issues: result.security,
            color: DevIQColors.warning,
          ),
        ],
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 10),
          _IssueGroup(
            title: 'Warnings',
            issues: result.warnings,
            color: DevIQColors.leetcode,
          ),
        ],
        if (result.suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          DevIQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggestions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in result.suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '·  ',
                          style: TextStyle(
                            color: DevIQColors.teal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        DevIQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Optimized code',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: optimizing ? null : onOptimize,
                    child: Text(
                      optimizing
                          ? 'Optimizing…'
                          : (optimized == null ? 'Generate' : 'Regenerate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (optimized != null && optimized!.isNotEmpty)
                CodeBlock(code: optimized!, language: language)
              else
                Text(
                  'Generate an optimized rewrite of your code.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              if (optimized != null && optimized!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: optimized!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Optimized code copied.')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 15),
                    label: const Text('Copy'),
                  ),
                ),
              ],
              if (result.fixedCode.isNotEmpty &&
                  result.fixedCode != optimized) ...[
                const SizedBox(height: 8),
                Text(
                  'Reviewer fix',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                CodeBlock(code: result.fixedCode, language: language),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IssueGroup extends StatelessWidget {
  const _IssueGroup({
    required this.title,
    required this.issues,
    required this.color,
  });
  final String title;
  final List<ReviewIssue> issues;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$title (${issues.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final i in issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (i.detail.isNotEmpty)
                    Text(
                      i.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
