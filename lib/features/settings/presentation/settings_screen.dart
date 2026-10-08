import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';
import '../../app/providers/app_providers.dart';
import '../../auth/presentation/auth_controller.dart';

/// Settings: theme, account, data. Destructive actions confirm first.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final auth = ref.watch(authProvider);
    return DevIQPage(
      reserveNav: false,
      children: [
        const DevIQSectionLabel('SETTINGS'),
        const SizedBox(height: 10),
        Text(
          'Preferences',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 16),
        const DevIQSectionLabel('THEME'),
        const SizedBox(height: 8),
        DevIQCard(
          child: RadioGroup<AppThemeMode>(
            groupValue: mode,
            onChanged: (v) {
              if (v != null) {
                ref.read(themeModeProvider.notifier).set(v);
              }
            },
            child: Column(
              children: [
                for (final m in AppThemeMode.values)
                  RadioListTile<AppThemeMode>(
                    value: m,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${m.name[0].toUpperCase()}${m.name.substring(1)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const DevIQSectionLabel('ACCOUNT'),
        const SizedBox(height: 8),
        DevIQCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline, size: 19),
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  auth.user?.email ?? 'Manage your profile',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => context.push('/profile'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_outlined, size: 19),
                title: const Text(
                  'History',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => context.push('/history'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const DevIQSectionLabel('SESSION'),
        const SizedBox(height: 8),
        if (auth.status == AuthStatus.authenticated)
          DevIQSecondaryButton(
            label: 'Logout (${auth.user?.email ?? ''})',
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/home');
            },
          )
        else
          DevIQButton(
            label: 'Sign in',
            icon: Icons.login,
            onPressed: () => context.push('/login'),
          ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'DevIQ · v1.0.0 · Developer Analytics Platform',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
