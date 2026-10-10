import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/deviq_colors.dart';

/// Consistent screen container: safe area + scroll + max content width.
class DevIQScaffold extends StatelessWidget {
  const DevIQScaffold({
    super.key,
    required this.body,
    this.header,
    this.bottomNav,
    this.fab,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  final Widget body;
  final Widget? header;
  final Widget? bottomNav;
  final Widget? fab;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: fab,
    bottomNavigationBar: bottomNav,
    body: SafeArea(
      child: Column(
        children: [
          // ignore: use_null_aware_elements (nullable single Widget has no ...? form)
          if (header != null) header!,
          Expanded(
            child: SingleChildScrollView(
              padding: padding,
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Premium solid card: #1A1A1A / white, 1px border, ~10px radius.
class DevIQCard extends StatelessWidget {
  const DevIQCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(DevIQRadius.card);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: Theme.of(context).dividerColor),
    );
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
    // Material-backed (not a bare DecoratedBox) so ink splashes and
    // ListTiles inside cards always have a proper Material ancestor.
    // The shadow lives on the outer transparent container to keep the
    // exact DevIQ card look.
    final mat = Material(
      color: Theme.of(context).cardColor,
      shape: shape,
      elevation: 0,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: DevIQShadows.card(dark),
      ),
      child: mat,
    );
  }
}

/// Primary button: white bg / black text (dark) — compact, 8–10px radius.
class DevIQButton extends StatelessWidget {
  const DevIQButton({
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
    final theme = Theme.of(context);
    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          );
    final btn = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DevIQRadius.button),
        ),
      ),
      child: child,
    );
    if (!expanded) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}

class DevIQSecondaryButton extends StatelessWidget {
  const DevIQSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.dividerColor),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DevIQRadius.button),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (!expanded) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}

/// Small uppercase section label with letter spacing.
class DevIQSectionLabel extends StatelessWidget {
  const DevIQSectionLabel(this.text, {super.key, this.accent});
  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (accent != null)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded pill (nav / filter / tag).
class DevIQPill extends StatelessWidget {
  const DevIQPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.dot,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DevIQRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(DevIQRadius.pill),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : (dark
                            ? DevIQColors.darkTextSecondary
                            : DevIQColors.lightTextSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text field with label.
class DevIQTextField extends StatelessWidget {
  const DevIQTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.monospace = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: monospace ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 17),
          ),
        ),
      ],
    );
  }
}

/// Single metric tile used in stat grids.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.sub,
  });

  final String label;
  final String value;
  final Color? accent;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent ?? theme.colorScheme.onSurface,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label/value row for dense stat lists.
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: accent ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// DevIQ brand mark (score-ring logo asset). Use everywhere the product
/// identity appears instead of ad-hoc letter tiles.
/// To swap in the exact designer file, replace assets/icon/deviq-logo.png.
class DevIQLogo extends StatelessWidget {
  const DevIQLogo({super.key, this.size = 28, this.radius = 8});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(
      'assets/icon/deviq-logo.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, _, _) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          'D',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.55,
          ),
        ),
      ),
    ),
  );
}

/// Avatar with initials fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.url, this.name, this.radius = 18});
  final String? url;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = (url ?? '').trim();
    if (u.isNotEmpty && u.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: u,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, _) => _fallback(theme),
          errorWidget: (_, _, _) => _fallback(theme),
        ),
      );
    }
    return _fallback(theme);
  }

  Widget _fallback(ThemeData theme) {
    final n = (name ?? '').trim();
    final initial = n.isEmpty ? 'D' : n.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      child: Text(
        initial,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: radius * 0.85),
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge(this.difficulty, {super.key});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final d = difficulty.toLowerCase();
    final c = d.startsWith('hard')
        ? DevIQColors.error
        : d.startsWith('med')
        ? DevIQColors.warning
        : DevIQColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DevIQRadius.pill),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        difficulty,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  const RankBadge(this.rank, {super.key});
  final String rank;

  @override
  Widget build(BuildContext context) {
    final c = DevIQColors.cfRankColor(rank);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DevIQRadius.pill),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        rank.isEmpty ? 'Unrated' : rank,
        style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ---- Async states ----
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Loading…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: theme.colorScheme.secondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              DevIQSecondaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry, this.icon});

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.cloud_off_outlined,
              size: 30,
              color: DevIQColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              DevIQSecondaryButton(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: onRetry,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer-free skeleton card (subtle pulsing blocks).
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key, this.height = 120});
  final double height;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.45, end: 0.9).animate(_c),
    child: Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(DevIQRadius.card),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
    ),
  );
}

/// Sign-in gate for features that require a backend session (all AI
/// endpoints). Shown instead of a raw 401 so signed-out users get a
/// clear path forward rather than "Missing or invalid authorization".
class SignInRequired extends StatelessWidget {
  const SignInRequired({super.key, this.feature = 'AI features'});

  final String feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevIQCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DevIQColors.ai.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DevIQColors.ai.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: DevIQColors.ai,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign in required',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$feature need a signed-in DevIQ account — it\u2019s free.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          DevIQButton(
            label: 'Sign in',
            icon: Icons.login,
            onPressed: () => context.push('/login'),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => context.push('/signup'),
              child: const Text('New here? Create an account'),
            ),
          ),
        ],
      ),
    );
  }
}
