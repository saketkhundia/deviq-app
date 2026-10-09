import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../data/models/analysis_models.dart';
import '../../../../shared/widgets/deviq_widgets.dart';
import '../../../../shared/widgets/markdown_body.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../insights_controller.dart';

/// AI Insights panel in the web reference style: icon header with
/// Copy / Hindi / Retry controls, dotted tab selector, content area and
/// a "N of 5 generated" footer with Generate-all. Lazy — nothing is
/// requested until the user generates.
class AiInsightsPanel extends ConsumerStatefulWidget {
  const AiInsightsPanel({super.key, required this.result});

  final AnalysisResult result;

  @override
  ConsumerState<AiInsightsPanel> createState() => _AiInsightsPanelState();
}

class _AiInsightsPanelState extends ConsumerState<AiInsightsPanel> {
  InsightMode _mode = InsightMode.quick;

  static const _tabColors = {
    InsightMode.quick: Color(0xFF58A6FF),
    InsightMode.roast: Color(0xFFF43F5E),
    InsightMode.plan: Color(0xFF22C55E),
    InsightMode.gaps: Color(0xFFEAB308),
    InsightMode.interview: Color(0xFFA78BFA),
  };

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Insight copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(insightsProvider);
    final authed = ref.watch(authProvider).status == AuthStatus.authenticated;
    if (!authed) {
      // Same backend session requirement as all AI endpoints.
      return const SignInRequired(feature: 'AI insights');
    }
    final entry = state.entry(_mode);
    final ready = entry.status == InsightStatus.ready;
    final generated = InsightMode.values
        .where((m) => state.entry(m).status == InsightStatus.ready)
        .length;
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
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF58A6FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: const Color(0xFF58A6FF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_outlined,
                        size: 17,
                        color: Color(0xFF58A6FF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Insights',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _modeSubtitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Wraps instead of squeezing on narrow phones.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeaderBtn(
                      icon: Icons.copy_outlined,
                      label: 'Copy',
                      onTap: !ready ? null : () => _copy(entry.text),
                    ),
                    _HeaderBtn(
                      icon: Icons.translate_outlined,
                      label: 'हिंदी',
                      selected: state.hindi,
                      onTap: () => ref
                          .read(insightsProvider.notifier)
                          .setHindi(!state.hindi),
                    ),
                    _HeaderBtn(
                      icon: Icons.refresh,
                      label: 'Retry',
                      onTap:
                          entry.status == InsightStatus.loading ||
                              state.generatingAll
                          ? null
                          : () => ref
                                .read(insightsProvider.notifier)
                                .generate(_mode, widget.result),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final m in InsightMode.values)
                      _ModeTab(
                        mode: m,
                        selected: _mode == m,
                        done: state.entry(m).status == InsightStatus.ready,
                        onTap: () => setState(() => _mode = m),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _content(theme, entry),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$generated of ${InsightMode.values.length} insights generated',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: state.generatingAll
                      ? null
                      : () => ref
                            .read(insightsProvider.notifier)
                            .generateAll(widget.result),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Text(
                      state.generatingAll ? 'Generating…' : 'Generate all →',
                      style: const TextStyle(
                        color: Color(0xFF58A6FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _modeSubtitle() => switch (_mode) {
    InsightMode.quick => 'Fast 3-line summary of your profile',
    InsightMode.roast => 'A good-natured roast, then one real tip',
    InsightMode.plan => 'A focused 7-day improvement plan',
    InsightMode.gaps => 'Top skill gaps with specific fixes',
    InsightMode.interview => 'Verdict plus readiness checklist',
  };

  Widget _content(ThemeData theme, InsightEntry entry) {
    switch (entry.status) {
      case InsightStatus.loading:
        return const LoadingState(message: 'Generating insight…');
      case InsightStatus.error:
        final mapped = signInNeededMessage(entry.text);
        if (mapped == null) {
          return ErrorState(
            message: entry.text,
            onRetry: () => ref
                .read(insightsProvider.notifier)
                .generate(_mode, widget.result),
          );
        }
        // Session expired mid-use: point at sign-in, retry won't help.
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
      case InsightStatus.ready:
        return MarkdownBody(text: entry.text);
      case InsightStatus.idle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nothing generated yet for ${_mode.label}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            DevIQButton(
              label: 'Generate ${_mode.label}',
              icon: Icons.auto_awesome_outlined,
              onPressed: () => ref
                  .read(insightsProvider.notifier)
                  .generate(_mode, widget.result),
            ),
          ],
        );
    }
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onTap == null
        ? theme.colorScheme.secondary.withValues(alpha: 0.45)
        : (selected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.secondary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.mode,
    required this.selected,
    required this.done,
    required this.onTap,
  });

  final InsightMode mode;
  final bool selected;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dot = _AiInsightsPanelState._tabColors[mode]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              mode.label,
              style: TextStyle(
                color: selected ? dot : theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (done) ...[
              const SizedBox(width: 5),
              Icon(Icons.check, size: 13, color: dot),
            ],
          ],
        ),
      ),
    );
  }
}
