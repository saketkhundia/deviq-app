import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/deviq_colors.dart';

/// Liquid-glass material system, built from scratch for Home.
///
/// Philosophy: every surface is a refractive lens, not a painted slab.
/// A luminous aurora field ([LiquidBackdrop]) sits behind the content;
/// panels ([LiquidGlass]) blur it, tint it, edge-light it with a 1px
/// luminous border, and catch a specular highlight across the top.
/// Buttons ([GlassPrimaryButton], [GlassGhostButton]) are the same
/// material at higher energy: signal-tinted or neutral, pressable,
/// with real blur beneath the label — never a flat fill.
///
/// Cost control: blur sigmas are modest (8–20), chips/buttons use the
/// lower end, and all motion collapses to zero under reduced-motion.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
    this.blur = 20,
    this.tint,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? tint;
  final Color? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final base = tint ?? LiquidGlassTokens.tint(dark);
    final edge = border ?? LiquidGlassTokens.edge(dark);
    final panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [LiquidGlassTokens.sheen(base, dark), base],
            ),
            border: Border.all(color: edge, width: 1),
            boxShadow: LiquidGlassTokens.elevation(dark),
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return panel;
    return GestureDetector(onTap: onTap, child: panel);
  }
}

/// Per-brightness glass recipes. Dark glass is smoke over aurora;
/// light glass is frosted white.
class LiquidGlassTokens {
  const LiquidGlassTokens._();

  static Color tint(bool dark) => dark
      ? const Color(0xFF151B22).withValues(alpha: 0.58)
      : Colors.white.withValues(alpha: 0.62);

  static Color edge(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.16)
      : const Color(0xFF0A0A0A).withValues(alpha: 0.09);

  /// Flat translucent fill for surfaces nested INSIDE a blurred lens
  /// (chips, tiles, inset strips). Same material family, no extra
  /// backdrop pass — stacked blurs stay cheap.
  static Color inset(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.05)
      : const Color(0xFF0A0A0A).withValues(alpha: 0.04);

  /// Specular wash blended over the tint for the top of a panel.
  static Color sheen(Color base, bool dark) => Color.alphaBlend(
    Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
    base,
  );

  static List<BoxShadow> elevation(bool dark) => [
    BoxShadow(
      color: dark
          ? Colors.black.withValues(alpha: 0.35)
          : const Color(0xFF0A0A0A).withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Signal-tinted glass for the primary action.
  static List<Color> primaryFill(bool dark) => dark
      ? [
          const Color(0xFF42E58B).withValues(alpha: 0.34),
          const Color(0xFF1FA855).withValues(alpha: 0.20),
        ]
      : [
          const Color(0xFF0E9F5D).withValues(alpha: 0.30),
          const Color(0xFF0E9F5D).withValues(alpha: 0.16),
        ];

  static Color primaryEdge(bool dark) => dark
      ? const Color(0xFF42E58B).withValues(alpha: 0.55)
      : const Color(0xFF0E9F5D).withValues(alpha: 0.50);

  static Color primaryText(bool dark) =>
      dark ? const Color(0xFFF2FFF7) : const Color(0xFFFFFFFF);
}

/// Aurora field: the light that glass refracts. Three whisper-alpha
/// glows — signal green, platform blue, codeforces violet — spread
/// down the page. Static paint, excluded from semantics.
class LiquidBackdrop extends StatelessWidget {
  const LiquidBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _AuroraPainter(dark: dark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AuroraBlob {
  const _AuroraBlob(this.fx, this.fy, this.color, this.alpha, this.radius);
  final double fx;
  final double fy;
  final Color color;
  final double alpha;
  final double radius;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      _AuroraBlob(0.88, 0.04, const Color(0xFF42E58B), dark ? 0.24 : 0.32, 280),
      _AuroraBlob(0.06, 0.22, const Color(0xFF58A6FF), dark ? 0.19 : 0.26, 260),
      _AuroraBlob(0.92, 0.52, const Color(0xFFA78BFA), dark ? 0.14 : 0.22, 250),
      _AuroraBlob(0.10, 0.80, const Color(0xFF42E58B), dark ? 0.10 : 0.18, 230),
    ];
    for (final b in blobs) {
      final center = Offset(size.width * b.fx, size.height * b.fy);
      final rect = Rect.fromCircle(center: center, radius: b.radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withValues(alpha: b.alpha),
            b.color.withValues(alpha: 0),
          ],
        ).createShader(rect);
      canvas.drawCircle(center, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.dark != dark;
}

/// Frosted section header: glass index chip, separator, uppercase
/// title, optional caption. Renders the same `INDEX / TITLE` language
/// as the rest of the workspace.
class GlassSectionHeader extends StatelessWidget {
  const GlassSectionHeader({
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
            LiquidGlass(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              borderRadius: 10,
              blur: 8,
              child: Text(
                index,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: dark
                      ? const Color(0xFF42E58B)
                      : const Color(0xFF0E9F5D),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
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
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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

/// Luminous hairline: transparent → edge-light → transparent.
class GlassDivider extends StatelessWidget {
  const GlassDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glow = dark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFF0A0A0A).withValues(alpha: 0.12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              glow.withValues(alpha: 0),
              glow,
              glow.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Luminous micro-bar: frosted track, glowing signal/platform fill.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 5,
  });

  /// 0–1 progress.
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF0A0A0A).withValues(alpha: 0.08),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  Color.alphaBlend(Colors.white.withValues(alpha: 0.25), color),
                ],
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 1px light line pinned to a lens edge: transparent at the ends,
/// luminous in the middle. Full-bleed, so the refraction cue spans
/// the whole width instead of floating mid-lens.
class _EdgeLight extends StatelessWidget {
  const _EdgeLight({super.key, required this.alpha});

  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: alpha),
          Colors.white.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

/// Shared press physics for glass buttons: gentle scale-down while
/// held, instant release. Zero-duration under reduced motion.
class _GlassPressable extends StatefulWidget {
  const _GlassPressable({
    required this.onTap,
    required this.child,
    required this.borderRadius,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double borderRadius;

  @override
  State<_GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<_GlassPressable> {
  bool _pressed = false;
  bool _focused = false;
  final FocusNode _node = FocusNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final activate =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space;
    if (activate && widget.onTap != null) {
      widget.onTap!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      focusable: widget.onTap != null,
      focused: _focused,
      child: Opacity(
        opacity: widget.onTap == null ? 0.55 : 1,
        child: Focus(
          focusNode: _node,
          canRequestFocus: widget.onTap != null,
          onFocusChange: (v) {
            if (_focused != v && mounted) setState(() => _focused = v);
          },
          onKeyEvent: (node, event) => _key(node, event),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.onTap == null ? null : (_) => _set(true),
            onTapUp: widget.onTap == null ? null : (_) => _set(false),
            onTapCancel: () => _set(false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: motion,
              curve: Curves.easeOut,
              child: Stack(
                children: [
                  widget.child,
                  // Visible keyboard focus ring. Mouse/touch users
                  // never see it; keyboard users always can.
                  if (_focused && widget.onTap != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              widget.borderRadius,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }
}

/// Primary glass action: signal-tinted refractive fill, luminous
/// signal border, bright label, soft green aura. 52px touch target.
class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !loading;
    final text = LiquidGlassTokens.primaryText(dark);
    final lens = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: DevIQControls.primaryHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: LiquidGlassTokens.primaryFill(dark),
            ),
            border: Border.all(
              color: LiquidGlassTokens.primaryEdge(dark),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (dark ? const Color(0xFF42E58B) : const Color(0xFF0E9F5D))
                        .withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // Full-bleed layers when stretched; content-sized when
          // inline (loose avoids infinite-width blowups in Rows).
          // Either way the gloss never floats as a middle band.
          // Center alignment is load-bearing: Stack defaults to
          // top-left, which rode labels ~5px high.
          child: Stack(
            alignment: Alignment.center,
            fit: expanded ? StackFit.expand : StackFit.loose,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: dark ? 0.14 : 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _EdgeLight(
                  key: const Key('glass-edge-light'),
                  alpha: dark ? 0.55 : 0.8,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: loading
                    ? Center(
                        child: SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: text,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: expanded
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.01,
                                color: text,
                              ),
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: 8),
                            Icon(icon, size: 18, color: text),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    final btn = _GlassPressable(
      onTap: enabled ? onPressed : null,
      borderRadius: 16,
      child: lens,
    );
    if (!expanded) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}

/// Quiet glass action: neutral refractive fill for secondary paths.
/// 48px touch target, never clipped: full-width stacked on phones.
class GlassGhostButton extends StatelessWidget {
  const GlassGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expanded = true,
    this.height = DevIQControls.secondaryHeight,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Full-width by default so actions match the primary lens; pass
  /// false for inline placement.
  final bool expanded;

  /// Lens height. Default 48px touch target; compact rows (terminal
  /// send) may pass a smaller value.
  final double height;

  /// Label size. Default 15; inline chips may pass a smaller value so
  /// the lens hugs the surrounding text instead of floating above it.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // Same glossy optics as the primary lens, in neutral tones: a
    // bright frosted cap up top melting into smoke, so the button
    // catches light instead of sitting as a dark slab.
    final capTop = dark
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.9);
    final capBottom = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.5);
    final lens = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [capTop, capBottom],
            ),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.3)
                  : const Color(0xFF0A0A0A).withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF0A0A0A).withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Full-bleed layers when stretched; content-sized when
          // inline (loose avoids infinite-width blowups in Rows).
          // Center alignment is load-bearing: Stack defaults to
          // top-left, which rode labels ~5px high.
          child: Stack(
            alignment: Alignment.center,
            fit: expanded ? StackFit.expand : StackFit.loose,
            children: [
              // Light catching the top edge.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _EdgeLight(
                  key: const Key('glass-edge-light'),
                  alpha: dark ? 0.6 : 1.0,
                ),
              ),
              // Grounding shade along the bottom edge for depth.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
                        Colors.black.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: dark ? 0.12 : 0.4),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.9,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final btn = _GlassPressable(onTap: onTap, borderRadius: 16, child: lens);
    if (!expanded) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}
