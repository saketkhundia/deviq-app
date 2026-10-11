import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/deviq_colors.dart';
import '../../data/models/platform_models.dart';

/// DevIQ signal component language: the shared typography, spacing and
/// visualization primitives behind the unified score, platform ledger,
/// activity fingerprint and skill profile.
///
/// Rules: tabular numerals for every measured value, mono for metadata
/// (usernames, dates), signal green only for DevIQ-owned metrics,
/// platform colors only on their own rows. On Home these primitives
/// float on liquid-glass panels over the aurora field.
class SignalType {
  const SignalType._();

  /// Tabular figures so aligned numbers never jitter.
  static TextStyle tabular(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle mono(BuildContext context, {double size = 11.5}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        height: 1.5,
        color: Theme.of(context).colorScheme.secondary,
      );
}

/// Numbered instrument header: `01 / UNIFIED SCORE`. The index is set
/// in signal green — the one decorative license in the system — and
/// the title stays quiet. Engineering-workspace structure.
class SignalSectionHeader extends StatelessWidget {
  const SignalSectionHeader({
    super.key,
    required this.index,
    required this.title,
    this.trailing,
    this.caption,
  });

  final String index;
  final String title;
  final Widget? trailing;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              index,
              style: SignalType.tabular(
                theme.textTheme.labelSmall?.copyWith(
                  color: DevIQColors.signalFor(dark),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '/',
                style: TextStyle(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                  fontSize: 11.5,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Thin analytical track bar. Flat fill, hairline-height, no glow.
class SignalBar extends StatelessWidget {
  const SignalBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 4,
    this.trackAlpha = 0.5,
  });

  /// 0–1 progress.
  final double value;
  final Color color;
  final double height;
  final double trackAlpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: theme.dividerColor.withValues(alpha: trackAlpha),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// One platform ledger row: brand dot, name, evidence caption,
/// tabular score and a micro comparison track. Rows are separated by
/// hairlines by the parent — never nested cards.
class PlatformLedgerRow extends StatelessWidget {
  const PlatformLedgerRow({
    super.key,
    required this.dot,
    required this.name,
    required this.evidence,
    required this.score,
    required this.delta,
    this.barColor,
    this.last = false,
  });

  final Color dot;
  final String name;
  final String evidence;
  final double score;
  final double delta;
  final Color? barColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final secondary = theme.colorScheme.secondary;
    final up = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide(color: theme.dividerColor)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      evidence,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SignalType.mono(context, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: SignalType.tabular(
                      theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${up ? '+' : ''}${delta.toStringAsFixed(0)} vs unified',
                    style: SignalType.tabular(
                      theme.textTheme.labelSmall?.copyWith(
                        color: up
                            ? DevIQColors.signalFor(dark)
                            : secondary,
                        fontWeight: up ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          SignalBar(
            value: score / 100,
            color: barColor ?? dot,
            height: 3,
          ),
        ],
      ),
    );
  }
}

/// Pure contribution fingerprint: precise grid, month + weekday
/// labels, intensity legend. Scrolls horizontally inside its bounds;
/// the page never overflows. Renders real [days] only — no sample
/// fill. Empty input renders nothing (callers own the empty state).
class SignalHeatmap extends StatelessWidget {
  const SignalHeatmap({super.key, required this.days});

  final List<ContributionDay> days;

  static const _cell = 11.0;
  static const _gap = 3.0;
  static const _gutter = 30.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    if (days.isEmpty) return const SizedBox.shrink();
    final weeks = <List<ContributionDay>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
    }
    final monthFmt = DateFormat('MMM');
    final labels = <String>[];
    var prevMonth = -1;
    for (final w in weeks) {
      final d = DateTime.tryParse(w.first.date);
      final m = d?.month ?? -1;
      if (m != prevMonth && m != -1) {
        labels.add(monthFmt.format(d!));
        prevMonth = m;
      } else {
        labels.add('');
      }
    }
    const weekdays = ['Mon', '', 'Wed', '', 'Fri', '', ''];
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.secondary,
      fontSize: 10,
    );
    Widget cell(ContributionDay d) => Container(
      width: _cell,
      height: _cell,
      decoration: BoxDecoration(
        color: DevIQColors.heatCell(dark, d.level),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  for (var r = 0; r < 7; r++)
                    Container(
                      width: _gutter,
                      height: _cell,
                      margin: const EdgeInsets.only(bottom: _gap),
                      alignment: Alignment.centerLeft,
                      child: Text(weekdays[r], style: labelStyle),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              for (var wi = 0; wi < weeks.length; wi++)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 16,
                        child: Text(labels[wi], style: labelStyle),
                      ),
                      for (final d in weeks[wi])
                        Padding(
                          padding: const EdgeInsets.only(bottom: _gap),
                          child: Semantics(
                            label:
                                '${d.date}: ${d.count} contributions',
                            child: cell(d),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less', style: labelStyle),
            const SizedBox(width: 6),
            for (var i = 0; i <= 4; i++)
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: DevIQColors.heatCell(dark, i),
                  borderRadius: BorderRadius.circular(2.5),
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
            const SizedBox(width: 3),
            Text('More', style: labelStyle),
          ],
        ),
      ],
    );
  }
}
