import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/deviq_colors.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/code_editor.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../app/providers/feature_controllers.dart';

/// Interactive code playground mirroring the web reference: hero,
/// toolbar (language · file · actions), stdin panel, stacked editor and
/// terminal frames, and tips. Everything executes on the DevIQ backend
/// cloud runner — the status pill reports live reachability.
class PlaygroundScreen extends ConsumerStatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  ConsumerState<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends ConsumerState<PlaygroundScreen> {
  final _code = TextEditingController();
  final _stdin = TextEditingController();
  final _file = TextEditingController();
  final _termInput = TextEditingController();
  String? _fieldLang;

  @override
  void initState() {
    super.initState();
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
    // Seed fields once the first frame lands (provider writes allowed).
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
    _code.dispose();
    _stdin.dispose();
    _file.dispose();
    _termInput.dispose();
    super.dispose();
  }

  /// Provider → fields, applied on language switch only. Runs in the
  /// listen callback (outside build), so controller updates are safe.
  void _onState(PlaygroundState? prev, PlaygroundState next) {
    if (!mounted || next.language == (_fieldLang ?? next.language)) {
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

  String _runCommand(PlaygroundLanguage lang, String file) {
    final f = file.isEmpty ? lang.defaultFile : file;
    return switch (lang.id) {
      'javascript' => 'node $f',
      'typescript' => 'ts-node $f',
      'python' => 'python $f',
      'java' => 'java ${f.replaceAll('.java', '')}',
      'c' => 'gcc $f && ./a.out',
      'cpp' => 'g++ $f && ./a.out',
      'go' => 'go run $f',
      'rust' => 'rustc $f && ./main',
      'ruby' => 'ruby $f',
      'csharp' => 'dotnet run',
      'kotlin' => 'kotlin $f',
      _ => '${lang.id} $f',
    };
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _code.text));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Code copied.')));
    }
  }

  Future<void> _download() async {
    final lang = PlaygroundLanguages.byId(
      ref.read(playgroundProvider).language,
    );
    final name = _file.text.trim().isEmpty
        ? lang.defaultFile
        : _file.text.trim();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(_code.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void _reset(PlaygroundLanguage lang) {
    _code.text = lang.template;
    ref.read(playgroundProvider.notifier).setCode(lang.template);
  }

  Future<void> _run() async {
    FocusScope.of(context).unfocus();
    await ref.read(playgroundProvider.notifier).run();
  }

  /// Terminal send: programs consume the pre-typed stdin, so a line sent
  /// here is appended to the stdin draft for the next run.
  void _sendTerminalLine() {
    final line = _termInput.text;
    if (line.isEmpty) return;
    _termInput.clear();
    final cur = _stdin.text;
    _stdin.text = cur.isEmpty ? line : '$cur\n$line';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to stdin — press Run to use it.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen<PlaygroundState>(playgroundProvider, _onState);
    final state = ref.watch(playgroundProvider);
    final notifier = ref.read(playgroundProvider.notifier);
    final lang = PlaygroundLanguages.byId(state.language);
    final mono = GoogleFonts.jetBrainsMono(fontSize: 12);

    return DevIQPage(
      reserveNav: false,
      children: [
        const DevIQSectionLabel('INTERACTIVE CODE PLAYGROUND'),
        const SizedBox(height: 10),
        Text(
          'Write code. Run it. See output.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.02,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'An in-app playground powered by the DevIQ cloud runner — write code in 11 languages and watch the terminal answer. Your program reads the stdin you type below, line by line.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        // ---- Toolbar ----
        Wrap(
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
              current: lang,
              onPick: (l) => notifier.setLanguage(l.id, l.template),
            ),
            _LivePill(live: state.runnerLive),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                'File',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: _file,
                  style: mono.copyWith(fontSize: 12),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DevIQSecondaryButton(
                label: 'Copy',
                icon: Icons.copy_outlined,
                onPressed: _copyCode,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DevIQSecondaryButton(
                label: 'Download',
                icon: Icons.download_outlined,
                onPressed: _download,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DevIQSecondaryButton(
                label: 'Reset',
                icon: Icons.refresh,
                onPressed: () => _reset(lang),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DevIQButton(
          label: state.running ? 'Running…' : 'Run',
          icon: Icons.play_arrow,
          loading: state.running,
          onPressed: _run,
        ),
        const SizedBox(height: 14),
        // ---- Stdin panel ----
        _StdinPanel(stdin: _stdin, theme: theme),
        const SizedBox(height: 10),
        // ---- Editor frame ----
        _EditorFrame(code: _code, file: _file, lang: lang, theme: theme),
        const SizedBox(height: 10),
        // ---- Terminal frame ----
        _TerminalFrame(
          state: state,
          lang: lang,
          fileName: _file.text.trim().isEmpty
              ? lang.defaultFile
              : _file.text.trim(),
          termInput: _termInput,
          onSend: _sendTerminalLine,
          onClear: notifier.clearResult,
          runCommand: _runCommand(
            lang,
            _file.text.trim().isEmpty ? lang.defaultFile : _file.text.trim(),
          ),
          theme: theme,
        ),
        if (state.error != null) ...[
          const SizedBox(height: 10),
          ErrorState(message: state.error!),
        ],
        const SizedBox(height: 14),
        const _TipsPanel(),
      ],
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.current, required this.onPick});

  final PlaygroundLanguage current;
  final ValueChanged<PlaygroundLanguage> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<PlaygroundLanguage>(
      initialValue: current,
      onSelected: onPick,
      tooltip: 'Select language',
      itemBuilder: (context) => [
        for (final l in PlaygroundLanguages.all)
          PopupMenuItem(value: l, child: Text(l.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                '${current.label} · cloud',
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

/// Green "Live" when the runner answered, amber "Sandbox" otherwise.
class _LivePill extends StatelessWidget {
  const _LivePill({required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? DevIQColors.success : DevIQColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DevIQRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            live ? 'Live' : 'Sandbox',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StdinPanel extends StatelessWidget {
  const _StdinPanel({required this.stdin, required this.theme});

  final TextEditingController stdin;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => DevIQCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'INPUT · STDIN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: stdin,
                builder: (context, v, _) {
                  final lines = v.text.isEmpty
                      ? 0
                      : '\n'.allMatches(v.text).length + 1;
                  return Text(
                    lines == 0
                        ? 'empty'
                        : '$lines line${lines == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: CodeEditor(
            controller: stdin,
            language: 'plaintext',
            minLines: 4,
            maxLines: 8,
            showBorder: false,
            hint: 'One input per line, in the order the program reads it.\nExample:\nAlex\n21',
          ),
        ),
      ],
    ),
  );
}

class _EditorFrame extends StatelessWidget {
  const _EditorFrame({
    required this.code,
    required this.file,
    required this.lang,
    required this.theme,
  });

  final TextEditingController code;
  final TextEditingController file;
  final PlaygroundLanguage lang;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => DevIQCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              const _MacDots(),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: file,
                  builder: (context, v, _) => Text(
                    v.text.trim().isEmpty ? lang.defaultFile : v.text.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: code,
                builder: (context, v, _) {
                  final lines = v.text.isEmpty
                      ? 0
                      : '\n'.allMatches(v.text).length + 1;
                  return Text(
                    '$lines lines · ${v.text.length} chars',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontSize: 10.5,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Padding(
          padding: const EdgeInsets.all(4),
          child: CodeEditor(
            controller: code,
            language: lang.highlightId ?? 'plaintext',
            minLines: 12,
            maxLines: 24,
            showBorder: false,
          ),
        ),
      ],
    ),
  );
}

class _MacDots extends StatelessWidget {
  const _MacDots();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Dot(color: Color(0xFFFF5F57)),
      SizedBox(width: 5),
      _Dot(color: Color(0xFFFEBC2E)),
      SizedBox(width: 5),
      _Dot(color: Color(0xFF28C840)),
    ],
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _TerminalFrame extends StatelessWidget {
  const _TerminalFrame({
    required this.state,
    required this.lang,
    required this.fileName,
    required this.termInput,
    required this.onSend,
    required this.onClear,
    required this.runCommand,
    required this.theme,
  });

  final PlaygroundState state;
  final PlaygroundLanguage lang;
  final String fileName;
  final TextEditingController termInput;
  final VoidCallback onSend;
  final VoidCallback onClear;
  final String runCommand;
  final ThemeData theme;

  String get _statusLabel => state.running
      ? 'RUNNING'
      : (state.result == null
            ? 'IDLE'
            : (state.result!.success ? 'SUCCESS' : 'ERROR'));

  Color get _statusColor => state.running
      ? DevIQColors.warning
      : (state.result == null
            ? theme.colorScheme.secondary
            : (state.result!.success
                  ? DevIQColors.success
                  : DevIQColors.error));

  Future<void> _copyOutput(BuildContext context) async {
    final text = [
      state.result?.output ?? '',
      state.result?.error ?? '',
    ].where((e) => e.isNotEmpty).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Output copied.')));
    }
  }

  @override
  Widget build(BuildContext context) => DevIQCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              Text(
                'TERMINAL',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: theme.colorScheme.secondary,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(width: 6),
              _LivePill(live: state.runnerLive),
              const Spacer(),
              Flexible(
                child: _StatusPill(label: _statusLabel, color: _statusColor),
              ),
              _TerminalMenu(
                hasResult: state.result != null,
                onCopy: () => _copyOutput(context),
                onClear: onClear,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TerminalView(
            output: state.result?.output ?? '',
            error: state.result?.error ?? '',
            running: state.running,
            exitCode: state.result?.exitCode,
            elapsedMs: state.result?.elapsedMs,
            command: state.result == null ? null : runCommand,
            showBorder: false,
            idleHint: '\$ — terminal ready. Press Run to compile & execute.\n@ if your program needs input, type it below and press Enter.',
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Text(
                '>',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DevIQColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: termInput,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: GoogleFonts.jetBrainsMono(fontSize: 12.5),
                  decoration: const InputDecoration(
                    hintText: 'Type here if the program needs input…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DevIQSecondaryButton(
                label: 'Send ↵',
                expanded: false,
                onPressed: onSend,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Terminal overflow menu (copy output / clear) — one compact target
/// instead of two icon buttons so the header never overflows phones.
class _TerminalMenu extends StatelessWidget {
  const _TerminalMenu({
    required this.hasResult,
    required this.onCopy,
    required this.onClear,
  });

  final bool hasResult;
  final VoidCallback onCopy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Terminal actions',
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Icon(
          Icons.more_vert,
          size: 18,
          color: theme.colorScheme.secondary,
        ),
      ),
      onSelected: (v) {
        if (v == 'copy') onCopy();
        if (v == 'clear') onClear();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          enabled: hasResult,
          child: const Row(
            children: [
              Icon(Icons.copy_outlined, size: 16),
              SizedBox(width: 10),
              Text('Copy output'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'clear',
          enabled: hasResult,
          child: const Row(
            children: [
              Icon(Icons.clear_all_outlined, size: 16),
              SizedBox(width: 10),
              Text('Clear terminal'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DevIQRadius.pill),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 10.5,
        letterSpacing: 0.3,
      ),
    ),
  );
}

class _TipsPanel extends StatelessWidget {
  const _TipsPanel();

  static const _tips = [
    'Syntax highlighting with line numbers; your code auto-saves per language.',
    'Every language runs on the DevIQ cloud runner — no setup needed.',
    'Programs read the stdin you type above, line by line, in order.',
    'Download any file to your device, or copy code and output anywhere.',
    'Long lines scroll sideways inside the editor and terminal.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'TIPS',
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
                for (var i = 0; i < _tips.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _tips.length - 1 ? 0 : 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•  ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _tips[i],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              height: 1.55,
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
      ),
    );
  }
}
