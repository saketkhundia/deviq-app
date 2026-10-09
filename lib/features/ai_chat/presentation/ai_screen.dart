import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/deviq_colors.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/widgets/markdown_body.dart';
import '../../app/providers/feature_controllers.dart';
import '../../auth/presentation/auth_controller.dart';

const _suggestions = [
  'Summarize my progress',
  'What are my weak areas?',
  'Give me a focused 7-day plan',
  'Am I interview ready?',
];

String _time(DateTime d) => DateFormat('hh:mm a').format(d.toLocal());

/// Ask AI chat mirroring the web reference: header with Clear chat,
/// suggestion pills, a framed conversation card (avatars, white user
/// bubbles, thinking indicator, markdown answers), composer and caption.
/// Answers come from POST /ai/insights with live profile context.
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final DateTime _openedAt = DateTime.now();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final t = _input.text;
    _input.clear();
    ref.read(chatProvider.notifier).send(t);
  }

  String _firstName() {
    final name = ref.read(authProvider).user?.name.trim() ?? '';
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) != next.messages.length) {
        _scrollToEnd();
      }
    });
    final state = ref.watch(chatProvider);
    final authed = ref.watch(authProvider).status == AuthStatus.authenticated;
    if (!authed) {
      // Backend AI endpoints require a session token — gate before any
      // request so users see a sign-in path, never a 401.
      return const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DevIQSectionLabel('AI ASSISTANT', accent: DevIQColors.ai),
            SizedBox(height: 12),
            SignInRequired(feature: 'AI chat'),
          ],
        ),
      );
    }
    final canSend = !state.sending;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DevIQSectionLabel('AI ASSISTANT', accent: DevIQColors.ai),
              const SizedBox(height: 8),
              Text(
                'Chat with Your Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Personalized answers from your analysis history — concise, actionable, no fluff.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (state.messages.isNotEmpty || state.error != null)
                    TextButton(
                      onPressed: state.sending
                          ? null
                          : () => ref.read(chatProvider.notifier).clear(),
                      child: const Text('Clear chat'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _suggestions.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: i == _suggestions.length - 1 ? 0 : 8,
                        ),
                        child: DevIQPill(
                          label: _suggestions[i],
                          onTap: state.sending
                              ? null
                              : () {
                                  _input.text = _suggestions[i];
                                  _send();
                                },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: DevIQCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Expanded(
                    child: state.messages.isEmpty && !state.sending
                        ? ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.all(14),
                            children: [
                              _AssistantRow(
                                text:
                                    'Hello ${_firstName()}! I\u2019m your DevIQ coach. I can see your analysis history and scores — ask me anything about your progress, weak areas, or what to do next.',
                                at: _openedAt,
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(14),
                            itemCount:
                                state.messages.length +
                                (state.sending ? 1 : 0) +
                                (state.error != null ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i < state.messages.length) {
                                final m = state.messages[i];
                                if (m.role == 'user') {
                                  return _UserRow(text: m.content, at: m.at);
                                }
                                return _AssistantRow(text: m.content, at: m.at);
                              }
                              if (state.sending && i == state.messages.length) {
                                return const _ThinkingBubble();
                              }
                              final err = state.error ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ErrorState(
                                  message: signInNeededMessage(err) ?? err,
                                ),
                              );
                            },
                          ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) {
                              if (canSend) _send();
                            },
                            style: theme.textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              hintText: 'Ask about your progress, weak areas, next steps…',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SendButton(
                          enabled: canSend,
                          sending: state.sending,
                          onTap: _send,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                    child: Center(
                      child: Text(
                        'Answers use your real profile data',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Coach avatar circle (star) used for every assistant message.
class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DevIQColors.github.withValues(alpha: 0.12),
        border: Border.all(color: DevIQColors.github.withValues(alpha: 0.35)),
      ),
      child: const Icon(
        Icons.star_outline,
        size: 15,
        color: DevIQColors.github,
      ),
    );
  }
}

class _AssistantRow extends StatelessWidget {
  const _AssistantRow({required this.text, required this.at});

  final String text;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CoachAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(text: text),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _time(at),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard.'),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.text, required this.at});

  final String text;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.62,
                ),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SelectableText(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF0A0A0A),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _time(at),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF737373),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _UserAvatar(),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: Consumer(
      builder: (context, ref, _) {
        final name = ref.watch(authProvider).user?.name.trim() ?? '';
        final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
        return Text(
          initial,
          style: const TextStyle(
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        );
      },
    ),
  );
}

/// "DevIQ AI is thinking…" with gently pulsing dots.
class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CoachAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    FadeTransition(
                      opacity:
                          TweenSequence([
                            TweenSequenceItem(
                              tween: Tween(begin: 0.25, end: 1.0),
                              weight: 1,
                            ),
                            TweenSequenceItem(
                              tween: Tween(begin: 1.0, end: 0.25),
                              weight: 1,
                            ),
                          ]).animate(
                            CurvedAnimation(
                              parent: _c,
                              curve: Interval(
                                i * 0.2,
                                0.4 + i * 0.2,
                                curve: Curves.easeInOut,
                              ),
                            ),
                          ),
                      child: Container(
                        width: 6,
                        height: 6,
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 4),
                        decoration: const BoxDecoration(
                          color: DevIQColors.github,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'DevIQ AI is thinking…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  final bool enabled;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = enabled && !sending;
    return InkWell(
      onTap: active ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.onSurface
              : theme.dividerColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: sending
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.secondary,
                ),
              )
            : Icon(
                Icons.send_rounded,
                size: 18,
                color: active
                    ? theme.scaffoldBackgroundColor
                    : theme.colorScheme.secondary,
              ),
      ),
    );
  }
}
