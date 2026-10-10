import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/deviq_colors.dart';
import '../../features/app/providers/app_providers.dart';
import '../../features/auth/presentation/auth_controller.dart';
import 'deviq_widgets.dart';

/// Compact mobile header: DevIQ branding + avatar + theme toggle.
/// Replaces the desktop floating pill navbar.
class DevIQHeader extends ConsumerWidget {
  const DevIQHeader({super.key, this.title, this.actions});

  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DevIQLogo(size: 28, radius: 8),
                const SizedBox(width: 8),
                Text(
                  'DevIQ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '· $title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          ...?actions,
          _ThemeToggle(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: ProfileAvatar(
              url: auth.user?.avatar,
              name: auth.user?.name,
              radius: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final dark = mode != AppThemeMode.light;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: dark ? 'Light mode' : 'Dark mode',
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .set(dark ? AppThemeMode.light : AppThemeMode.dark),
      icon: Icon(
        dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 19,
      ),
    );
  }
}

/// Custom bottom navigation — pill-style, DevIQ visual language.
/// Never the default BottomNavigationBar.
class DevIQBottomNav extends StatelessWidget {
  const DevIQBottomNav({super.key, required this.active, this.onTab});

  final String active;
  final ValueChanged<String>? onTab;

  /// Primary tabs: Home · Analyze · Interview Prep · Ask AI, plus the
  /// More sheet (Compare, Playground, Review, Profile, History,
  /// Settings). Active tab renders as a filled pill with icon + label
  /// (reference behavior); inactive tabs are muted icons only.
  static const _tabs = [
    ('home', Icons.home_outlined, 'Home'),
    ('analyze', Icons.analytics_outlined, 'Analyze'),
    ('interview', Icons.work_outline, 'Interview'),
    ('ai', Icons.smart_toy_outlined, 'Ask AI'),
    ('more', Icons.apps_outlined, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (id, icon, label) in _tabs)
              _NavItem(
                icon: icon,
                label: label,
                selected: active == id,
                onTap: () {
                  if (active == id || onTab == null) return;
                  onTab!(id);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DevIQRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 12 : 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(DevIQRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// "More" sheet: secondary destinations in the same card language.
class MoreSheet extends StatelessWidget {
  const MoreSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('Compare', Icons.compare_arrows_outlined, '/compare', DevIQColors.teal),
      ('Playground', Icons.terminal_outlined, '/playground', null),
      ('Review', Icons.rate_review_outlined, '/review', DevIQColors.ai),
      ('Profile', Icons.person_outlined, '/profile', null),
      ('History', Icons.history_outlined, '/history', null),
      ('Settings', Icons.settings_outlined, '/settings', null),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            for (final (label, icon, route, accent) in items)
              ListTile(
                leading: Icon(
                  icon,
                  size: 20,
                  color: (accent is Color)
                      ? accent
                      : theme.colorScheme.secondary,
                ),
                title: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(route);
                },
              ),
          ],
        ),
      ),
    );
  }
}
