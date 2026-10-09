import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/deviq_colors.dart';

/// Animated score ring: 3px stroke, starts at -90°, ~1400ms counter.
/// Mobile diameter defaults to 148 (major visual element, not tiny).
class ScoreRing extends StatefulWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.maximum = 100,
    this.label,
    this.diameter = 148,
    this.duration = const Duration(milliseconds: 1400),
    this.color,
  });

  final double score;
  final double maximum;
  final String? label;
  final double diameter;

  /// Fixed ring color. Defaults to the standard score thresholds.
  final Color? color;
  final Duration duration;

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void didUpdateWidget(ScoreRing old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _c
        ..duration = widget.duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? DevIQColors.scoreColor(widget.score);
    return SizedBox(
      width: widget.diameter,
      height: widget.diameter + (widget.label == null ? 0 : 22),
      child: Column(
        children: [
          SizedBox(
            width: widget.diameter,
            height: widget.diameter,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, _) {
                final v = widget.score * _anim.value;
                return CustomPaint(
                  painter: _RingPainter(
                    progress: (v / widget.maximum).clamp(0, 1),
                    color: color,
                    track: theme.dividerColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          v.toStringAsFixed(0),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.02,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/ ${widget.maximum.toStringAsFixed(0)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide / 2) - 4;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, trackPaint);
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
