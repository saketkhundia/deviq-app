import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/theme/deviq_colors.dart';
import '../../../data/models/ai_models.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/code_editor.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../app/providers/feature_controllers.dart';
import '../../auth/presentation/auth_controller.dart';

const _sampleCode = '''def fibonacci(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

print(fibonacci(10))''';

/// Naive language detection for the Auto-Detect selector. Keyword-based,
/// honest about uncertainty — the resolved label is always shown.
String detectLanguageId(String code) {
  final c = code.toLowerCase();
  var best = 'javascript';
  var bestHits = 0;
  void consider(String id, List<String> keywords) {
    var hits = 0;
    for (final k in keywords) {
      if (c.contains(k)) hits++;
    }
    if (hits > bestHits) {
      bestHits = hits;
      best = id;
    }
  }

  consider('python', ['def ', 'import ', 'print(', 'self', 'elif ', 'lambda ']);
  consider('javascript', [
    'console.log',
    'function ',
    '=>',
    'const ',
    'let ',
    '===',
  ]);
  consider('typescript', [': string', ': number', 'interface ', 'readonly ']);
  consider('java', ['public class', 'system.out', 'public static void']);
  consider('c', ['#include', 'printf(', 'malloc(']);
  consider('cpp', ['std::', 'cout <<', '#include <iostream>']);
  consider('go', ['package main', 'func ', 'fmt.']);
  consider('rust', ['fn ', 'let mut', 'println!']);
  consider('ruby', ['puts ', 'end\n', 'def ']);
  consider('csharp', ['using system', 'console.writeline', 'namespace ']);
  consider('kotlin', ['fun ', 'val ', 'println(']);
  return best;
}

/// AI code review mirroring the web reference: hero, editor frame with
/// toolbar + live footer, reviewing progress, then summary, complexity,
/// optimize, categorized findings, quality, suggestions and fixed code.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _code = TextEditingController();
  final _scroll = ScrollController();
  final _topKey = GlobalKey();
  String _language = 'auto';
  Timer? _ticker;
  int _elapsed = 0;
  bool _optimizing = false;

  @override
  void dispose() {
    _code.dispose();
    _scroll.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  String get _effectiveLang =>
      _language == 'auto' ? detectLanguageId(_code.text) : _language;

  String get _languageLabel {
    if (_language != 'auto') {
      return PlaygroundLanguages.byId(_language).label;
    }
    if (_code.text.trim().isEmpty) return 'Auto-Detect';
    final detected = PlaygroundLanguages.byId(_effectiveLang).label;
    return 'Auto-Detect ($detected)';
  }

  void _review() {
    if (_code.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paste some code first.')));
      return;
    }
    FocusScope.of(context).unfocus();
    _ticker?.cancel();
    setState(() => _elapsed = 0);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
    ref
        .read(reviewProvider.notifier)
        .review(code: _code.text, language: _effectiveLang)
        .whenComplete(() {
          _ticker?.cancel();
        });
  }

  Future<void> _optimize() async {
    if (_optimizing) return;
    setState(() => _optimizing = true);
    await ref
        .read(reviewProvider.notifier)
        .optimize(code: _code.text, language: _effectiveLang);
    if (mounted) setState(() => _optimizing = false);
  }

  void _scrollTop() {
    final ctx = _topKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _loadFixed(String fixed) {
    _code.text = fixed;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fixed code loaded into the editor.')),
    );
    _scrollTop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(reviewProvider);
    final authed = ref.watch(authProvider).status == AuthStatus.authenticated;
    final loading = state.status == ReviewStatus.loading;
    return DevIQPage(
      reserveNav: false,
      controller: _scroll,
      children: [
        Column(key: _topKey, children: const [SizedBox.shrink()]),
        const DevIQSectionLabel('AI CODE REVIEW', accent: DevIQColors.ai),
        const SizedBox(height: 10),
        Text(
          'Paste code. Get a senior-level review.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.02,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'DevIQ flags bugs, estimates time & space complexity, generates an optimized rewrite with quality gains and areas to improve, catches security issues, grades code quality, and suggests concrete fixes.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        _EditorFrame(
          code: _code,
          language: _language,
          languageLabel: _languageLabel,
          onLanguage: (v) => setState(() => _language = v),
          onSample: () => setState(() => _code.text = _sampleCode),
          onClear: () => setState(_code.clear),
          onReview: authed ? _review : null,
          reviewing: loading,
          elapsed: _elapsed,
        ),
        if (!authed) ...[
          const SizedBox(height: 12),
          const SignInRequired(feature: 'AI code reviews'),
        ] else ...[
          if (loading) ...[
            const SizedBox(height: 12),
            _ReviewingCard(language: _effectiveLang, elapsed: _elapsed),
          ],
          if (state.status == ReviewStatus.failure) ...[
            const SizedBox(height: 12),
            _ReviewError(
              message: state.error ?? 'Review failed.',
              onRetry: _review,
            ),
          ],
          if (state.status == ReviewStatus.success && state.result != null) ...[
            const SizedBox(height: 12),
            _ReviewResults(
              result: state.result!,
              optimized: state.optimized,
              optimizing: _optimizing,
              language: _effectiveLang,
              onOptimize: _optimize,
              onLoadFixed: _loadFixed,
            ),
            const SizedBox(height: 16),
            Center(
              child: DevIQSecondaryButton(
                label: 'Go to review ↓',
                expanded: false,
                onPressed: _scrollTop,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Editor frame: toolbar (language menu + actions), code surface with
/// live footer. Review action lives here, like the web reference.
class _EditorFrame extends StatelessWidget {
  const _EditorFrame({
    required this.code,
    required this.language,
    required this.languageLabel,
    required this.onLanguage,
    required this.onSample,
    required this.onClear,
    required this.onReview,
    required this.reviewing,
    required this.elapsed,
  });

  final TextEditingController code;
  final String language;
  final String languageLabel;
  final ValueChanged<String> onLanguage;
  final VoidCallback onSample;
  final VoidCallback onClear;
  final VoidCallback? onReview;
  final bool reviewing;
  final int elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightLang = language == 'auto'
        ? (PlaygroundLanguages.byId(detectLanguageId(code.text)).highlightId ??
              'plaintext')
        : (PlaygroundLanguages.byId(language).highlightId ?? 'plaintext');
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Language',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                _LanguageMenu(
                  label: languageLabel,
                  value: language,
                  onPick: onLanguage,
                ),
                _GhostBtn(label: 'Try a sample', onTap: onSample),
                _GhostBtn(label: 'Clear', onTap: onClear),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(4),
            child: CodeEditor(
              controller: code,
              language: highlightLang,
              minLines: 10,
              maxLines: 24,
              showBorder: false,
              hint: '// Paste your code here, then press Review',
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: code,
                    builder: (context, v, _) {
                      final lines = v.text.isEmpty
                          ? 1
                          : '\n'.allMatches(v.text).length + 1;
                      return Text(
                        '$lines lines · ${v.text.length} chars',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      );
                    },
                  ),
                ),
                if (onReview != null)
                  SizedBox(
                    width: 150,
                    child: DevIQButton(
                      label: reviewing
                          ? 'Reviewing… ${elapsed}s'
                          : 'Review Code',
                      loading: false,
                      onPressed: reviewing ? null : onReview,
                    ),
                  )
                else
                  Text(
                    'Max ~30KB per review',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onReview == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                'Max ~30KB per review',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final String value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onPick,
      tooltip: 'Review language',
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'auto', child: Text('Auto-Detect')),
        for (final l in PlaygroundLanguages.all)
          PopupMenuItem(value: l.id, child: Text(l.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(DevIQRadius.button),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DevIQRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DevIQRadius.button),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Reviewing progress card with elapsed timer and determinate bar.
class _ReviewingCard extends StatelessWidget {
  const _ReviewingCard({required this.language, required this.elapsed});

  final String language;
  final int elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = PlaygroundLanguages.byId(language).label.toLowerCase();
    return DevIQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI is reviewing your $label code… (usually 30–90s)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (elapsed / 60).clamp(0.05, 0.97),
              minHeight: 4,
              backgroundColor: theme.dividerColor,
              valueColor: const AlwaysStoppedAnimation(DevIQColors.github),
            ),
          ),
        ],
      ),
    );
  }
}

/// Failure with session-expiry mapped to a sign-in action.
class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mapped = signInNeededMessage(message);
    if (mapped == null) {
      return ErrorState(message: message, onRetry: onRetry);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorState(message: mapped),
        const SizedBox(height: 8),
        DevIQSecondaryButton(
          label: 'Sign in again',
          icon: Icons.login,
          onPressed: () => context.push('/login'),
        ),
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
    required this.onLoadFixed,
  });

  final CodeReviewResult result;
  final String? optimized;
  final bool optimizing;
  final String language;
  final VoidCallback onOptimize;
  final ValueChanged<String> onLoadFixed;

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return DevIQColors.error;
      case 'HIGH':
        return DevIQColors.warning;
      case 'MEDIUM':
        return const Color(0xFFFB923C);
      case 'LOW':
        return DevIQColors.github;
      default:
        return DevIQColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(result: result),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            final cards = [
              _ComplexityCard(
                title: 'TIME COMPLEXITY',
                info: result.timeComplexity,
              ),
              _ComplexityCard(
                title: 'SPACE COMPLEXITY',
                info: result.spaceComplexity,
              ),
            ];
            if (c.maxWidth >= 520) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cards[0], const SizedBox(height: 10), cards[1]],
            );
          },
        ),
        const SizedBox(height: 10),
        _OptimizePanel(
          optimized: optimized,
          optimizing: optimizing,
          language: language,
          onOptimize: onOptimize,
        ),
        const SizedBox(height: 10),
        _IssueGroup(
          dot: DevIQColors.error,
          title: 'BUGS',
          count: result.bugs.length,
          emptyText: 'No bugs found — clean run.',
          children: [
            for (final issue in result.bugs)
              _BugCard(issue: issue, severityColor: _severityColor),
          ],
        ),
        const SizedBox(height: 10),
        _IssueGroup(
          dot: DevIQColors.warning,
          title: 'WARNINGS',
          count: result.warnings.length,
          emptyText: 'No warnings — no risky edge cases spotted.',
          children: [
            for (final issue in result.warnings)
              _BugCard(issue: issue, severityColor: _severityColor),
          ],
        ),
        const SizedBox(height: 10),
        _IssueGroup(
          dot: DevIQColors.warning,
          title: 'SECURITY ISSUES',
          count: result.security.length,
          emptyText: 'No security issues detected.',
          children: [
            for (final issue in result.security)
              _BugCard(issue: issue, severityColor: _severityColor),
          ],
        ),
        const SizedBox(height: 10),
        _IssueGroup(
          dot: DevIQColors.github,
          title: 'CODE QUALITY',
          count: result.quality.length,
          emptyText: 'No quality notes.',
          children: [
            for (final q in result.quality)
              _QualityCard(title: q.title, detail: q.detail),
          ],
        ),
        const SizedBox(height: 10),
        _IssueGroup(
          dot: DevIQColors.success,
          title: 'SUGGESTIONS',
          count: result.suggestions.length,
          emptyText: 'No suggestions — ship it.',
          children: [
            for (final s in result.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s.display,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _FixedCodePanel(
          result: result,
          language: language,
          onLoadFixed: onLoadFixed,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});

  final CodeReviewResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScoreRing(
            score: result.score,
            diameter: 84,
            duration: const Duration(milliseconds: 900),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUMMARY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.summary.isEmpty
                      ? 'Review complete. See findings below.'
                      : result.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _LegendDot(
                      color: DevIQColors.error,
                      text: 'Bug — will fail on normal inputs',
                    ),
                    _LegendDot(
                      color: DevIQColors.warning,
                      text: 'Warning — might fail on edge cases',
                    ),
                    _LegendDot(
                      color: DevIQColors.success,
                      text: 'Suggestion — quality improvement',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComplexityCard extends StatelessWidget {
  const _ComplexityCard({required this.title, required this.info});

  final String title;
  final ComplexityInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info.value.isEmpty ? '—' : info.value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DevIQColors.codeforces,
            ),
          ),
          if (info.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              info.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptimizePanel extends StatelessWidget {
  const _OptimizePanel({
    required this.optimized,
    required this.optimizing,
    required this.language,
    required this.onOptimize,
  });

  final String? optimized;
  final bool optimizing;
  final String language;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DevIQColors.codeforces,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OPTIMIZED TIME & SPACE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _PurpleButton(
                  label: 'Optimize',
                  onTap: optimizing ? null : onOptimize,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: 'Get an '),
                      _b(theme, 'optimized rewrite'),
                      const TextSpan(
                        text: ' of your code with better time & space complexity. Press the button to generate it below.',
                      ),
                    ],
                  ),
                ),
                if (optimized != null && optimized!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CodeBlock(code: optimized!, language: language),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: optimized!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Optimized code copied.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _b(ThemeData theme, String t) => TextSpan(
    text: t,
    style: TextStyle(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _PurpleButton extends StatelessWidget {
  const _PurpleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(DevIQRadius.button),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DevIQColors.codeforces,
        borderRadius: BorderRadius.circular(DevIQRadius.button),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ),
  );
}

/// Grouped findings panel: dotted header with count, divider, then items
/// or a muted empty line — matching the web BUGS/WARNINGS pattern.
class _IssueGroup extends StatelessWidget {
  const _IssueGroup({
    required this.dot,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.children,
  });

  final Color dot;
  final String title;
  final int count;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: children.isEmpty
                ? Text(
                    emptyText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        children[i],
                        if (i != children.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BugCard extends StatelessWidget {
  const _BugCard({required this.issue, required this.severityColor});

  final ReviewIssue issue;
  final Color Function(String severity) severityColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sev = severityColor(issue.severity);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sev.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sev.withValues(alpha: 0.35)),
                ),
                child: Text(
                  issue.severity.isEmpty
                      ? 'NOTE'
                      : issue.severity.toUpperCase(),
                  style: TextStyle(
                    color: sev,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                issue.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (issue.line != null)
                Text(
                  '· line ${issue.line}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
            ],
          ),
          if (issue.category.isNotEmpty || issue.confidence != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (issue.category.isNotEmpty) issue.category,
                if (issue.confidence != null) 'confidence ${issue.confidence}%',
              ].join('  '),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
          if (issue.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              issue.detail,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
          if (issue.trigger.isNotEmpty) ...[
            const SizedBox(height: 6),
            _LabeledLine(label: 'Trigger: ', text: issue.trigger),
          ],
          if (issue.expected.isNotEmpty) ...[
            const SizedBox(height: 4),
            _LabeledLine(
              label: 'Expected: ',
              text: issue.expected,
              labelColor: DevIQColors.success,
            ),
          ],
          if (issue.actual.isNotEmpty) ...[
            const SizedBox(height: 4),
            _LabeledLine(
              label: 'Actual: ',
              text: issue.actual,
              labelColor: DevIQColors.error,
            ),
          ],
          if (issue.fix.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DevIQColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DevIQColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                'Fix: ${issue.fix}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  height: 1.55,
                  color: DevIQColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledLine extends StatelessWidget {
  const _LabeledLine({
    required this.label,
    required this.text,
    this.labelColor,
  });

  final String label;
  final String text;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: labelColor ?? theme.colorScheme.onSurface,
            ),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: DevIQColors.github,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          if (title.isNotEmpty && detail.isNotEmpty) const SizedBox(height: 6),
          if (detail.isNotEmpty)
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
        ],
      ),
    );
  }
}

class _FixedCodePanel extends StatelessWidget {
  const _FixedCodePanel({
    required this.result,
    required this.language,
    required this.onLoadFixed,
  });

  final CodeReviewResult result;
  final String language;
  final ValueChanged<String> onLoadFixed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'FIXED CODE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (result.repairStrategy.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DevIQColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: DevIQColors.success.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          result.repairStrategy.toUpperCase(),
                          style: const TextStyle(
                            color: DevIQColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DevIQButton(
                        label: 'Load into editor',
                        expanded: true,
                        onPressed: result.fixedCode.isEmpty
                            ? null
                            : () => onLoadFixed(result.fixedCode),
                      ),
                    ),
                    TextButton(
                      onPressed: result.fixedCode.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: result.fixedCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fixed code copied.'),
                                ),
                              );
                            },
                      child: const Text('Copy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (result.fixedCode.isNotEmpty) ...[
            Divider(height: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CodeBlock(code: result.fixedCode, language: language),
            ),
          ],
        ],
      ),
    );
  }
}
