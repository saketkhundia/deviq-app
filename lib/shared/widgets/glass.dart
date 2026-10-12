import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../core/theme/design_tokens.dart';
import 'deviq_widgets.dart';
import '../../core/theme/deviq_colors.dart';

/// Liquid-glass floating lens: deep backdrop blur + frosted smoke
/// tint + luminous 1px border + specular top sweep with a full-bleed
/// edge-light line. Built for floating chrome (bottom navigation)
/// drifting over scrolling content on AMOLED black — the blur sigma
/// is deliberately deep so the lens reads while the page moves.
/// Set [enabled] false as the cheap fallback where blur is
/// unsupported or too expensive.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 24,
    this.blur = 14,
    this.enabled = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double blur;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final base = GlassTokens.surface(dark);
    final material = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: dark ? 0.10 : 0.35),
              base,
            ),
            base,
          ],
        ),
        border: Border.all(color: GlassTokens.border(dark)),
        boxShadow: [
          BoxShadow(
            color: dark
                ? const Color.fromRGBO(0, 0, 0, 0.45)
                : const Color.fromRGBO(0, 0, 0, 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Full-bleed light: specular sweep plus a 1px edge-light line
      // pinned to the true top edge. The Stack sizes to the child;
      // positioned layers add no size of their own.
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    GlassTokens.highlight(dark),
                    GlassTokens.highlight(dark).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: dark ? 0.35 : 0.8),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
    if (!enabled || blur <= 0) {
      return ClipRRect(borderRadius: radius, child: material);
    }
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: material,
      ),
    );
  }
}

/// Tab item for [SlidingPillNavigation].
class PillNavItem {
  const PillNavItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.avatarUrl,
    this.avatarName,
  });

  final String id;

  /// Outline glyph for the idle state.
  final IconData icon;

  /// Filled glyph for the selected state.
  final IconData selectedIcon;
  final String label;

  /// When set, the cell renders a user avatar (reference style)
  /// instead of the icon glyphs.
  final String? avatarUrl;
  final String? avatarName;

  bool get showsAvatar => avatarUrl != null || avatarName != null;
}

/// Floating capsule tab bar in Apple liquid glass, built from scratch.
///
/// A deep-blur frosted lens (sigma 30) over a luminous gradient tint,
/// ringed by a 1px edge-light border and floated on a soft drop
/// shadow. A signal-tinted lens glides between equal cells on a
/// short ease curve (zero-duration under reduced motion) to mark the
/// active tab; taps retarget the same animation — nothing queues.
/// Compact by construction (~64px + system inset) so page clearance
/// math never changes.
class SlidingPillNavigation extends StatefulWidget {
  const SlidingPillNavigation({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PillNavItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  State<SlidingPillNavigation> createState() => _SlidingPillNavigationState();
}

class _SlidingPillNavigationState extends State<SlidingPillNavigation>
    with SingleTickerProviderStateMixin {
  /// Hovered cell while scrubbing (and while settling). Null when idle.
  int? _hover;

  /// True between finger-down (past slop) and lift.
  bool _dragging = false;

  /// Left edge of the travelling capsule in bar-inner coordinates,
  /// owned by the finger (dragging) or the spring (settling).
  double _capsuleLeft = 0;

  /// True while the release spring is flying. Taps cancel it.
  bool _settling = false;

  late final AnimationController _settleCtrl;

  @override
  void initState() {
    super.initState();
    _settleCtrl = AnimationController(vsync: this)
      ..addListener(_onSettleTick)
      ..addStatusListener(_onSettleStatus);
  }

  @override
  void dispose() {
    _closeProfileMenu();
    _settleCtrl.dispose();
    super.dispose();
  }

  void _onSettleTick() {
    if (_settling && mounted) {
      setState(() => _capsuleLeft = _settleCtrl.value);
    }
  }

  void _onSettleStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && _settling && mounted) {
      final target = _hover;
      final current = widget.items
          .indexWhere((e) => e.id == widget.selectedId)
          .clamp(0, widget.items.length - 1);
      setState(() => _settling = false);
      if (target != null && target != current) {
        widget.onSelect(widget.items[target].id);
      }
    }
  }

  void _beginDrag(double innerDx, double cell, double innerW) {
    _settleCtrl.stop();
    setState(() {
      _dragging = true;
      _settling = false;
      _hover = (innerDx / cell).floor().clamp(0, widget.items.length - 1);
      _capsuleLeft = (innerDx - (cell - 6) / 2).clamp(
        3.0,
        innerW - 3.0 - (cell - 6),
      );
    });
  }

  void _moveDrag(double innerDx, double cell, double innerW) {
    setState(() {
      _hover = (innerDx / cell).floor().clamp(0, widget.items.length - 1);
      _capsuleLeft = (innerDx - (cell - 6) / 2).clamp(
        3.0,
        innerW - 3.0 - (cell - 6),
      );
    });
  }

  void _release(int index, double cell, double velocity) {
    final target = _hover;
    setState(() => _dragging = false);
    if (target == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      if (target != index) widget.onSelect(widget.items[target].id);
      return;
    }
    // Spring-like settle onto the nearest destination, then route.
    // Render clamps every frame, so even a fling overshoot can never
    // leave the bar.
    final dest = 3 + target * cell;
    setState(() => _settling = true);
    _settleCtrl.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 320, damping: 28),
        _capsuleLeft,
        dest,
        velocity.clamp(-2500, 2500),
      ),
    );
  }

  void _cancelInteractions() {
    if (_settling || _dragging) {
      _settleCtrl.stop();
      setState(() {
        _settling = false;
        _dragging = false;
        _hover = null;
      });
    }
  }

  OverlayEntry? _menuEntry;

  /// Anchors the quick menu to the bar itself, wherever the bar lives.
  final LayerLink _menuLink = LayerLink();

  /// Long-press on the avatar: a frosted quick menu (Ask AI,
  /// Analyze, Compare) pinned 8px above the bar's top-right end. The
  /// follower tracks the bar itself, so the menu can never strand
  /// off-viewport no matter where the bar is hosted.
  void _openProfileMenu() {
    if (_menuEntry != null || !mounted) return;
    _menuEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeProfileMenu,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _menuLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(-8, -26),
            child: _MenuEntrance(
              child: _ProfileMenu(
                onPick: (route) {
                  _closeProfileMenu();
                  GoRouter.of(context).push(route);
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_menuEntry!);
  }

  void _closeProfileMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final index = widget.items
        .indexWhere((e) => e.id == widget.selectedId)
        .clamp(0, widget.items.length - 1);
    final duration = AuthTokens.motion(context, AuthTokens.navSlide);
    return SafeArea(
      top: false,
      child: CompositedTransformTarget(
        link: _menuLink,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? const Color.fromRGBO(0, 0, 0, 0.55)
                  : const Color.fromRGBO(0, 0, 0, 0.14),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final innerW = c.maxWidth - 8;
            final cell = innerW / widget.items.length;
            final pillW = cell - 6;
            double clampLeft(double v) => v.clamp(3.0, innerW - 3.0 - pillW);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              // Hold and slide: the capsule tracks the finger
              // continuously with zero easing; lift-off springs onto
              // the nearest tab and routes. Pure taps fall through
              // untouched, and only horizontal motion is ever
              // claimed, so page scrolling outside the bar is
              // unaffected.
              onHorizontalDragStart: (d) =>
                  _beginDrag(d.localPosition.dx - 4, cell, innerW),
              onHorizontalDragUpdate: (d) =>
                  _moveDrag(d.localPosition.dx - 4, cell, innerW),
              onHorizontalDragEnd: (d) =>
                  _release(index, cell, d.velocity.pixelsPerSecond.dx),
              onHorizontalDragCancel: () => setState(() {
                _dragging = false;
                _hover = null;
              }),
              // Clip.none lets the selection glow breathe past the
              // bar edge. The Stack sizes to the bar background;
              // positioned layers add no size of their own.
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: dark
                                ? [
                                    Colors.white.withValues(alpha: 0.24),
                                    Colors.white.withValues(alpha: 0.09),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.85),
                                    Colors.white.withValues(alpha: 0.6),
                                  ],
                          ),
                          border: Border.all(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.32)
                                : const Color(0xFF0A0A0A)
                                      .withValues(alpha: 0.12),
                          ),
                        ),
                        // Full-bleed light: specular sweep plus a 1px
                        // edge-light line pinned to the true top edge,
                        // and a grounding shade along the bottom.
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.center,
                                    colors: [
                                      Colors.white.withValues(
                                        alpha: dark ? 0.2 : 0.5,
                                      ),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: _NavEdgeLight(),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 24,
                              right: 24,
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0),
                                      Colors.black.withValues(
                                        alpha: dark ? 0.5 : 0.15,
                                      ),
                                      Colors.black.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // The travelling capsule. Finger-owned
                            // while dragging (direct tracking, no
                            // easing), spring-owned while settling,
                            // then handed back to the selected-id
                            // glide. Constant width, clamped inside
                            // the bar — it can never overshoot.
                            if (_dragging || _settling)
                              Positioned(
                                left: clampLeft(_capsuleLeft),
                                top: 3,
                                bottom: 3,
                                width: pillW,
                                child: const _TravelLens(
                                  key: Key('nav-capsule'),
                                ),
                              )
                            else
                              AnimatedPositioned(
                                duration: duration,
                                curve: Curves.easeOutCubic,
                                left: index * cell + 3,
                                top: 3,
                                bottom: 3,
                                width: cell - 6,
                                child: const _TravelLens(),
                              ),
                            Row(
                              children: [
                                for (var i = 0; i < widget.items.length; i++)
                                  Expanded(
                                    child: _PillCell(
                                      item: widget.items[i],
                                      selected:
                                          i == index ||
                                          (_dragging && i == _hover),
                                      onTap: () {
                                        _cancelInteractions();
                                        if (i != index) {
                                          widget.onSelect(widget.items[i].id);
                                        }
                                      },
                                      // Hold the avatar for quick actions.
                                      // Suppressed mid-scrub so a hold that
                                      // turns into a slide never pops it.
                                      onLongPress:
                                          widget.items[i].id == 'profile' &&
                                              !_dragging
                                          ? _openProfileMenu
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

/// Frosted selection lens shared by the travelling capsule and the
/// resting indicator: milky refractive fill, bright rim, hot top
/// edge, grounding base shade.
class _TravelLens extends StatelessWidget {
  const _TravelLens({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.13),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.5)
              : const Color(0xFF0A0A0A).withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: dark ? 0.18 : 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: dark ? 0.7 : 0.9),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft scale-in entrance for the quick menu: grows from its
/// bottom-right anchor over ~160ms. Instant under reduced motion.
class _MenuEntrance extends StatelessWidget {
  const _MenuEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0.94, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: reduceMotion ? 1 : (0.4 + 0.6 * v),
        child: Transform.scale(
          scale: v,
          alignment: Alignment.bottomRight,
          child: c,
        ),
      ),
      child: child,
    );
  }
}

/// Frosted quick menu for a long-press on the Profile tab: Ask AI,
/// Analyze, Compare — and nothing else. No Settings, no History.
class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final rows = [
      ('Ask AI', Icons.smart_toy_outlined, '/ai', DevIQColors.codeforces),
      ('Analyze', Icons.analytics_outlined, '/analyze', DevIQColors.success),
      ('Compare', Icons.compare_arrows_outlined, '/compare', DevIQColors.github),
    ];
    return SizedBox(
      width: 208,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.08),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
              ),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.28)
                    : const Color(0xFF0A0A0A).withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, icon, route, accent) in rows)
                  _MenuRow(
                    label: label,
                    icon: icon,
                    accent: accent,
                    onTap: () => onPick(route),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 19, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: theme.colorScheme.secondary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1px light line catching the bar's top edge.
class _NavEdgeLight extends StatelessWidget {
  const _NavEdgeLight();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: dark ? 0.65 : 0.9),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _PillCell extends StatelessWidget {
  const _PillCell({
    required this.item,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  /// Hold action (used by the Profile tab for its quick menu).
  /// Null on every other tab.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fg = selected
        ? (dark ? Colors.white : const Color(0xFF0B3D24))
        : (dark
              ? Colors.white.withValues(alpha: 0.62)
              : Colors.black.withValues(alpha: 0.5));
    // NOTE: no Center/Align wrapper here on purpose. This bar lives
    // in Scaffold.bottomNavigationBar with a finite-loose maxHeight;
    // an Align would expand every cell (and the sliding indicator)
    // to full screen. InkWell shrink-wraps its content instead.
    return _TapScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AuthTokens.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.showsAvatar)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: ProfileAvatar(
                    url: item.avatarUrl,
                    name: item.avatarName,
                    radius: 11,
                  ),
                )
              else
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: fg,
                  semanticLabel: item.label,
                ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                  // Submerged depth: soft drop shadow lifts the label
                  // off the lens like print under water.
                  shadows: selected
                      ? [
                          Shadow(
                            color: Colors.black.withValues(
                              alpha: dark ? 0.5 : 0.25,
                            ),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gentle press scale for tab cells. Zero-duration under reduced
/// motion. Tap handling stays on the inner InkWell so ripples,
/// semantics and test taps behave exactly as before.
class _TapScale extends StatefulWidget {
  const _TapScale({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 120);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: motion,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }
}

/// Hairline divider with a centered label, used between primary
/// credentials actions and social sign-in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = Expanded(
      child: Container(height: 1, color: theme.dividerColor),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// Google sign-in action: outlined lens + official multicolor "G"
/// glyph, label-driven (no emoji). Screens wire [onPressed] to
/// `AuthController.signInWithGoogle` and pass `loading` while the
/// native picker/backend exchange is in flight.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTokens.radiusButton),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.secondary,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(SimpleIcons.google, size: 18),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Continue with Google',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
/// Primary auth action: light surface + dark text (dark appearance),
/// instant press feedback, restrained loading state.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AuthTokens.darkAction : AuthTokens.lightAction;
    final fg = dark ? AuthTokens.darkActionFg : AuthTokens.lightActionFg;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.45),
          disabledForegroundColor: fg.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTokens.radiusButton),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

/// Auth text field: spec surfaces, precise borders, focus feedback.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.suffix,
    this.obscure = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fill = dark ? AuthTokens.darkInput : AuthTokens.lightInput;
    final border = dark ? AuthTokens.darkBorder : AuthTokens.lightBorder;
    final side = BorderSide(color: border);
    OutlineInputBorder outline(BorderSide s) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AuthTokens.radiusField),
      borderSide: s,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: dark
                  ? AuthTokens.darkTextSecondary
                  : AuthTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
            // 16px keeps iOS from zooming on focus.
            fontSize: DevIQControls.inputFontSize,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
            suffixIcon: suffix,
            filled: true,
            fillColor: fill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: outline(side),
            enabledBorder: outline(side),
            focusedBorder: outline(
              BorderSide(
                color:
                    (dark
                            ? AuthTokens.darkTextSecondary
                            : AuthTokens.lightTextSecondary)
                        .withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            errorBorder: outline(const BorderSide(color: AuthTokens.error)),
            focusedErrorBorder: outline(
              const BorderSide(color: AuthTokens.error, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password visibility toggle with semantic label. Tapping only flips
/// obscuring — the field keeps focus and content.
class VisibilityToggle extends StatelessWidget {
  const VisibilityToggle({
    super.key,
    required this.obscured,
    required this.onTap,
  });

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: obscured ? 'Show password' : 'Hide password',
    onPressed: onTap,
    icon: Icon(
      obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: 19,
    ),
  );
}
