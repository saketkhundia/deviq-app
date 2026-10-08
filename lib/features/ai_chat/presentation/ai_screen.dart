import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../app/providers/feature_controllers.dart';
import '../../analyze/presentation/analyze_controller.dart';

const _suggestions = [
  'Summarize my progress',
  'What are my weak areas?',
  'Give me a focused 7-day plan',
  'Am I interview ready?',
];

/// AI assistant answering from the user's real DevIQ profile data.
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _input.text;
    _input.clear();
    ref.read(chatProvider.notifier).send(t);
    Future.delayed(
        const Duration(milliseconds: 120),
        () {
          if (_scroll.hasClients) {
            _scroll.animateTo(_scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatProvider);
    final hasAnalysis = ref.watch(analyzeProvider).result != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DevIQSectionLabel('AI ASSISTANT', accent: DevIQColors.ai),
              const SizedBox(height: 8),
              Text('Chat with Your Profile',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(
                  'Personalized answers from your analysis history — concise, actionable, no fluff.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary, height: 1.5)),
              if (!hasAnalysis)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DevIQColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color:
                            DevIQColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                      'Tip: run an analysis first so answers use your real profile data.',
                      style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        Expanded(
          child: state.messages.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suggested prompts',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in _suggestions)
                            DevIQPill(
                              label: s,
                              onTap: () {
                                _input.text = s;
                                _send();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: state.messages.length +
                      (state.sending ? 1 : 0) +
                      (state.error != null ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i < state.messages.length) {
                      final m = state.messages[i];
                      return _Bubble(
                          mine: m.role == 'user',
                          text: m.content,
                          at: m.at);
                    }
                    if (state.sending && i == state.messages.length) {
                      return const _Bubble(
                          mine: false, text: '…', at: null);
                    }
                    return ErrorState(message: state.error ?? '');
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: theme.dividerColor))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                        hintText: 'Ask about your profile…'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: state.sending ? null : _send,
                  icon: state.sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_upward, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.mine, required this.text, required this.at});
  final bool mine;
  final String text;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: mine ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border:
              mine ? null : Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: mine
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (at != null)
                  Text(Formatters.dateTime(at!),
                      style: TextStyle(
                          fontSize: 10,
                          color: (mine
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.secondary)
                              .withValues(alpha: 0.7))),
                if (!mine) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Copied to clipboard.')));
                    },
                    child: Icon(Icons.copy,
                        size: 12,
                        color: theme.colorScheme.secondary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
