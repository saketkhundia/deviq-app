import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// Liquid-Glass-inspired surface: backdrop blur + translucent tint +
/// fine border + top-edge highlight. Reserved for floating chrome
/// (navigation); never for list content. Set [enabled] false as the
/// cheap fallback where blur is unsupported or too expensive.
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
    final material = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GlassTokens.surface(dark),
        borderRadius: radius,
        border: Border.all(color: GlassTokens.border(dark)),
        boxShadow: [
          BoxShadow(
            color: dark
                ? const Color.fromRGBO(0, 0, 0, 0.35)
                : const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
        child: child,
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
  });

  final String id;

  /// Outline glyph for the idle state.
  final IconData icon;

  /// Filled glyph for the selected state.
  final IconData selectedIcon;
  final String label;
}

/// Capsule navigation with a genuinely sliding selection indicator.
/// Equal cells keep position math exact; the indicator glides between
/// cells on a short ease curve (zero-duration under reduced motion).
/// Taps retarget the same animation — nothing queues.
class SlidingPillNavigation extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final index = items
        .indexWhere((e) => e.id == selectedId)
        .clamp(0, items.length - 1);
    final duration = AuthTokens.motion(context, AuthTokens.navSlide);
    // Softly contrasting translucent surface — never a solid pill.
    final pill = dark
        ? const Color.fromRGBO(255, 255, 255, 0.1)
        : const Color.fromRGBO(0, 0, 0, 0.06);
    final pillBorder = dark
        ? const Color.fromRGBO(255, 255, 255, 0.16)
        : const Color.fromRGBO(0, 0, 0, 0.1);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassSurface(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, c) {
              final cell = c.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: index * cell + 3,
                    top: 0,
                    bottom: 0,
                    width: cell - 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: pill,
                        borderRadius: BorderRadius.circular(
                          AuthTokens.radiusPill,
                        ),
                        border: Border.all(color: pillBorder),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _PillCell(
                            item: items[i],
                            selected: i == index,
                            onTap: () {
                              if (i != index) onSelect(items[i].id);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
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
  });

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fg = selected
        ? (dark ? Colors.white : Colors.black87)
        : (dark
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.45));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AuthTokens.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 21,
              color: fg,
              semanticLabel: item.label,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
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
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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
