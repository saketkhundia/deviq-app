import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/deviq_colors.dart';
import '../../features/app/providers/app_providers.dart';
import '../../features/auth/presentation/auth_controller.dart';
import 'deviq_widgets.dart';
import 'glass.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/profile'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ProfileAvatar(
                url: auth.user?.avatar,
                name: auth.user?.name,
                radius: 15,
              ),
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
    final theme = Theme.of(context);
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
        size: 20,
        color: theme.colorScheme.secondary,
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

  /// Primary tabs: Home · Analyze · Compare · Play, plus the More
  /// sheet (Interview Prep, Ask AI, Review, Profile, History,
  /// Settings). The active tab glides a translucent indicator with a
  /// filled icon + label; the rest are muted icons + labels.
  static const _tabs = [
    PillNavItem(
      id: 'home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    PillNavItem(
      id: 'analyze',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      label: 'Analyze',
    ),
    PillNavItem(
      id: 'compare',
      icon: Icons.compare_arrows_outlined,
      selectedIcon: Icons.compare_arrows_rounded,
      label: 'Compare',
    ),
    PillNavItem(
      id: 'play',
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal_rounded,
      label: 'Play',
    ),
    PillNavItem(
      id: 'more',
      icon: Icons.apps_outlined,
      selectedIcon: Icons.apps_rounded,
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) => SlidingPillNavigation(
    items: _tabs,
    selectedId: active,
    onSelect: (id) {
      if (id != active) onTab?.call(id);
    },
  );
}

/// "More" sheet: secondary destinations in the same card language.
class MoreSheet extends StatelessWidget {
  const MoreSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('Interview Prep', Icons.work_outline, '/interview', DevIQColors.warning),
      ('Ask AI', Icons.smart_toy_outlined, '/ai', DevIQColors.codeforces),
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
