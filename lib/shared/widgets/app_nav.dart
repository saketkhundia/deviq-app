import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            onTap: () => context.go('/profile'),
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

/// Custom bottom navigation: Home · Interview · Play · Review ·
/// Profile. Never the default BottomNavigationBar. Profile renders
/// the user's avatar (reference style); a long-press on it opens a
/// frosted quick menu (Ask AI, Analyze, Compare).
class DevIQBottomNav extends ConsumerWidget {
  const DevIQBottomNav({super.key, required this.active, this.onTab});

  final String active;
  final ValueChanged<String>? onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return SlidingPillNavigation(
      items: [
        const PillNavItem(
          id: 'home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
        ),
        const PillNavItem(
          id: 'interview',
          icon: Icons.work_outlined,
          selectedIcon: Icons.work_rounded,
          label: 'Interview',
        ),
        const PillNavItem(
          id: 'play',
          icon: Icons.terminal_outlined,
          selectedIcon: Icons.terminal_rounded,
          label: 'Play',
        ),
        const PillNavItem(
          id: 'review',
          icon: Icons.rate_review_outlined,
          selectedIcon: Icons.rate_review,
          label: 'Review',
        ),
        PillNavItem(
          id: 'profile',
          icon: Icons.person_outlined,
          selectedIcon: Icons.person_rounded,
          label: 'Profile',
          avatarUrl: auth.user?.avatar,
          avatarName: auth.user?.name,
        ),
      ],
      selectedId: active,
      onSelect: (id) {
        if (id != active) onTab?.call(id);
      },
    );
  }
}
