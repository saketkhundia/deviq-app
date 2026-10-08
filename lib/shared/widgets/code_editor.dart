import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart' as dark_hl;
import 'package:flutter_highlight/themes/github.dart' as light_hl;
import 'package:google_fonts/google_fonts.dart';

/// Mobile code editor: transparent [TextField] layered over a highlighted
/// render with a synchronized line-number gutter. Editing stays native
/// (cursor, selection, copy/paste, undo/redo via platform), while the
/// backdrop provides language-aware highlighting.
class CodeEditor extends StatefulWidget {
  const CodeEditor({
    super.key,
    required this.controller,
    this.language = 'python',
    this.minLines = 10,
    this.maxLines = 22,
    this.readOnly = false,
    this.hint = '// Start typing…',
  });

  final TextEditingController controller;
  final String language;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final String hint;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final _scroll = ScrollController();
  final _gutterScroll = ScrollController();
  String _text = '';

  @override
  void initState() {
    super.initState();
    _text = widget.controller.text;
    widget.controller.addListener(_onText);
    _scroll.addListener(_sync);
  }

  void _onText() {
    if (mounted && _text != widget.controller.text) {
      setState(() => _text = widget.controller.text);
    }
  }

  void _sync() {
    if (_gutterScroll.hasClients && _scroll.hasClients) {
      _gutterScroll.jumpTo(_scroll.offset.clamp(
          0, _gutterScroll.position.maxScrollExtent));
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _scroll.dispose();
    _gutterScroll.dispose();
    super.dispose();
  }

  int get _lines =>
      _text.isEmpty ? 1 : '\n'.allMatches(_text).length + 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final mono =
        GoogleFonts.jetBrainsMono(fontSize: 12.5, height: 1.55);
    final lineH = 12.5 * 1.55;
    final minH = lineH * widget.minLines + 24;
    final maxH = lineH * widget.maxLines + 24;

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gutter
            Container(
              width: 44,
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(color: theme.dividerColor)),
              ),
              child: SingleChildScrollView(
                controller: _gutterScroll,
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 1; i <= _lines.clamp(1, 9999); i++)
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 10, left: 6),
                        child: Text('$i',
                            style: mono.copyWith(
                                color: theme.colorScheme.secondary
                                    .withValues(alpha: 0.6),
                                fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
            // Code surface
            Expanded(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: minH, maxHeight: maxH),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Stack(
                    children: [
                      // Highlight backdrop (ignore pointer so taps hit field)
                      IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              12, 12, 12, 12),
                          child: HighlightView(
                            _text.isEmpty ? ' ' : _text,
                            language: widget.language,
                            theme: dark ? dark_hl.atomOneDarkTheme : light_hl.githubTheme,
                            textStyle: mono.copyWith(
                                color: theme.colorScheme.onSurface),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      // Editable layer
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            12, 12, 12, 12),
                        child: TextField(
                          controller: widget.controller,
                          readOnly: widget.readOnly,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          style: mono.copyWith(
                              color: Colors.transparent),
                          cursorColor: dark
                              ? Colors.white
                              : Colors.black,
                          // Transparent text + visible selection/cursor.
                          selectionControls:
                              MaterialTextSelectionControls(),
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            hintStyle: mono.copyWith(
                                color: theme.colorScheme.secondary
                                    .withValues(alpha: 0.7)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only highlighted block (results, fixed code, explanations).
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.language = 'python'});

  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightView(
          code,
          language: language,
          theme: dark ? dark_hl.atomOneDarkTheme : light_hl.githubTheme,
          textStyle: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              height: 1.55,
              color: theme.colorScheme.onSurface),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Terminal view: monospace output with status line.
class TerminalView extends StatelessWidget {
  const TerminalView({
    super.key,
    this.output = '',
    this.error = '',
    this.running = false,
    this.exitCode,
    this.elapsedMs,
  });

  final String output;
  final String error;
  final bool running;
  final int? exitCode;
  final int? elapsedMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final mono = GoogleFonts.jetBrainsMono(
        fontSize: 12.5,
        height: 1.5,
        color: dark ? const Color(0xFFE5E5E5) : const Color(0xFF1A1A1A));
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140, maxHeight: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0D0D0D) : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (running)
              Row(children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: mono.color)),
                const SizedBox(width: 8),
                Text('Running…',
                    style: mono.copyWith(fontSize: 12)),
              ])
            else if (output.isEmpty && error.isEmpty)
              Text('\$ awaiting output',
                  style: mono.copyWith(
                      color: mono.color?.withValues(alpha: 0.5),
                      fontSize: 12))
            else ...[
              if (output.isNotEmpty)
                SelectableText(output, style: mono),
              if (error.isNotEmpty)
                SelectableText(error,
                    style: mono.copyWith(
                        color: const Color(0xFFFB7185))),
              if (exitCode != null || elapsedMs != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'exit=$exitCode · ${elapsedMs ?? 0}ms',
                    style: mono.copyWith(
                        fontSize: 11,
                        color: mono.color
                            ?.withValues(alpha: 0.55)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
