import 'package:flutter/material.dart';

/// Clean AI-response body: headings, bullet lines with accent markers,
/// **bold** inline, and airy paragraphs. Dependency-free mini-markdown
/// shared by AI Insights and Ask AI.
class MarkdownBody extends StatelessWidget {
  const MarkdownBody({super.key, required this.text, this.accent});

  final String text;
  final Color? accent;

  static final _bullet = RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+');
  static final _bold = RegExp(r'\*\*(.+?)\*\*');
  static final _heading = RegExp(r'^#{1,4}\s+');

  static List<TextSpan> inline(String s, TextStyle base, TextStyle bold) {
    final spans = <TextSpan>[];
    var i = 0;
    for (final m in _bold.allMatches(s)) {
      if (m.start > i) spans.add(TextSpan(text: s.substring(i, m.start)));
      spans.add(TextSpan(text: m.group(1), style: bold));
      i = m.end;
    }
    if (i < s.length) spans.add(TextSpan(text: s.substring(i)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dot = accent ?? const Color(0xFF58A6FF);
    final base =
        theme.textTheme.bodyMedium?.copyWith(
          height: 1.7,
          color: theme.colorScheme.onSurface,
        ) ??
        const TextStyle(height: 1.7);
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    final heading = base.copyWith(fontWeight: FontWeight.w800, fontSize: 15);

    final blocks = <Widget>[];
    List<String> pendingBullets = [];

    void flushBullets() {
      if (pendingBullets.isEmpty) return;
      for (final b in pendingBullets) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(style: base, children: inline(b, base, bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      pendingBullets = [];
    }

    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        flushBullets();
        blocks.add(const SizedBox(height: 4));
        continue;
      }
      final head = _heading.firstMatch(line.trim());
      if (head != null) {
        flushBullets();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: SelectableText(
              line.trim().substring(head.end).trim(),
              style: heading,
            ),
          ),
        );
        continue;
      }
      final m = _bullet.firstMatch(line);
      if (m != null) {
        pendingBullets.add(line.substring(m.end).trim());
      } else {
        flushBullets();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableText.rich(
              TextSpan(style: base, children: inline(line.trim(), base, bold)),
            ),
          ),
        );
      }
    }
    flushBullets();
    if (blocks.isNotEmpty && blocks.last is SizedBox) blocks.removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
