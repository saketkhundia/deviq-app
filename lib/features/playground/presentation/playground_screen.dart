import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/deviq_theme.dart';
import '../../../shared/widgets/code_editor.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../app/providers/feature_controllers.dart';

/// Mobile coding experience: language selector, native editor surface,
/// stdin, run/copy/reset, tabbed editor-or-terminal on small screens.
class PlaygroundScreen extends ConsumerStatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  ConsumerState<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends ConsumerState<PlaygroundScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _code = TextEditingController();
  final _stdin = TextEditingController();
  final _file = TextEditingController();
  String? _fieldLang;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this); // Editor | Input | Output
    // Field → provider (event-driven only, never during build).
    _code.addListener(() {
      final cur = ref.read(playgroundProvider);
      if (_code.text != cur.code) {
        ref.read(playgroundProvider.notifier).setCode(_code.text);
      }
    });
    _stdin.addListener(() {
      final cur = ref.read(playgroundProvider);
      if (_stdin.text != cur.stdin) {
        ref.read(playgroundProvider.notifier).setStdin(_stdin.text);
      }
    });
    // Seed fields once the first frame lands (provider writes allowed here).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(playgroundProvider);
      final lang = PlaygroundLanguages.byId(s.language);
      _fieldLang = s.language;
      _file.text = lang.defaultFile;
      if (s.code.isEmpty) {
        _code.text = lang.template;
        ref.read(playgroundProvider.notifier).setCode(lang.template);
      } else {
        _code.text = s.code;
      }
      if (s.stdin.isNotEmpty) _stdin.text = s.stdin;
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _code.dispose();
    _stdin.dispose();
    _file.dispose();
    super.dispose();
  }

  /// Provider → fields, applied on language switch only. Runs in the
  /// listen callback (outside build), so controller updates are safe.
  void _onState(PlaygroundState? prev, PlaygroundState next) {
    if (!mounted || next.language == (_fieldLang ?? next.language)) {
      // Same language: adopt async draft loads into a pristine field only.
      if (_code.text.isEmpty && next.code.isNotEmpty) {
        _code.text = next.code;
      }
      if (_stdin.text.isEmpty && next.stdin.isNotEmpty) {
        _stdin.text = next.stdin;
      }
      return;
    }
    _fieldLang = next.language;
    final lang = PlaygroundLanguages.byId(next.language);
    _file.text = lang.defaultFile;
    _code.text = next.code.isEmpty ? lang.template : next.code;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen<PlaygroundState>(playgroundProvider, _onState);
    final state = ref.watch(playgroundProvider);
    final notifier = ref.read(playgroundProvider.notifier);
    final lang = PlaygroundLanguages.byId(state.language);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DevIQSectionLabel('CODE PLAYGROUND'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final l in PlaygroundLanguages.all)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: DevIQPill(
                          label: l.label,
                          selected: l.id == state.language,
                          onTap: () {
                            notifier.setLanguage(l.id, l.template);
                            _code.text = ref.read(playgroundProvider).code;
                            _file.text = l.defaultFile;
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _file,
                        style: DevIQText.mono(context, size: 12),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Reset to template',
                    onPressed: () {
                      _code.text = lang.template;
                      notifier.setCode(lang.template);
                    },
                    icon: const Icon(Icons.refresh, size: 19),
                  ),
                  IconButton(
                    tooltip: 'Copy code',
                    onPressed: () {
                      // Clipboard via editable selection; fallback: select-all feedback.
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Long-press the editor to copy code.')));
                    },
                    icon: const Icon(Icons.copy_outlined, size: 19),
                  ),
                  FilledButton.icon(
                    onPressed:
                        state.running ? null : () => _runAndShow(notifier),
                    icon: state.running
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.play_arrow, size: 16),
                    label: Text(state.running ? 'Run' : 'Run'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TabBar(
                controller: _tabs,
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.secondary,
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Editor'),
                  Tab(text: 'Input'),
                  Tab(text: 'Output'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: CodeEditor(
                    controller: _code,
                    language: lang.highlightId ?? 'plaintext'),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Standard input (stdin)',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    CodeEditor(
                      controller: _stdin,
                      language: 'plaintext',
                      minLines: 6,
                      maxLines: 14,
                      hint: 'input for your program…',
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.error != null)
                      ErrorState(message: state.error!),
                    TerminalView(
                      output: state.result?.output ?? '',
                      error: state.result?.error ?? '',
                      running: state.running,
                      exitCode: state.result?.exitCode,
                      elapsedMs: state.result?.elapsedMs,
                    ),
                    if (state.result != null &&
                        !state.running) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.result!.success
                            ? 'Completed successfully'
                            : state.result!.timedOut
                                ? 'Timed out — try a shorter program'
                                : 'Finished with exit code ${state.result!.exitCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _runAndShow(PlaygroundController notifier) async {
    _tabs.animateTo(2);
    await notifier.run();
  }
}
