import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/auth_models.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/layout/responsive.dart';
import '../../analyze/presentation/analyze_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';

/// Profile: identity, usernames, stats, sync, logout, delete.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _site = TextEditingController();
  final _loc = TextEditingController();
  final _gh = TextEditingController();
  final _lc = TextEditingController();
  final _cf = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(profileProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _bio, _site, _loc, _gh, _lc, _cf]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(UserProfile p) {
    if (_filled) return;
    _filled = true;
    _name.text = p.displayName;
    _bio.text = p.bio;
    _site.text = p.website;
    _loc.text = p.location;
    _gh.text = p.githubUsername;
    _lc.text = p.leetcodeUsername;
    _cf.text = p.codeforcesHandle;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final cur = ref.read(profileProvider).profile ?? UserProfile.empty();
    final ok = await ref
        .read(profileProvider.notifier)
        .save(
          cur.copyWith(
            displayName: _name.text.trim(),
            bio: _bio.text.trim(),
            website: _site.text.trim(),
            location: _loc.text.trim(),
            githubUsername: _gh.text.trim(),
            leetcodeUsername: _lc.text.trim(),
            codeforcesHandle: _cf.text.trim(),
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Profile saved.' : 'Save failed.')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all sessions. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final prof = ref.watch(profileProvider);
    final history = ref.watch(historyProvider);
    if (prof.profile != null) _fill(prof.profile!);

    return DevIQPage(
      reserveNav: false,
      children: [
        const DevIQSectionLabel('PROFILE'),
        const SizedBox(height: 12),
        DevIQCard(
          child: Row(
            children: [
              ProfileAvatar(
                url: auth.user?.avatar ?? prof.profile?.avatar,
                name: auth.user?.name ?? prof.profile?.displayName,
                radius: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.user?.name ?? prof.profile?.displayName ?? 'Guest',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((auth.user?.email ?? '').isNotEmpty)
                      Text(
                        auth.user!.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    if (auth.status != AuthStatus.authenticated)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: DevIQSecondaryButton(
                          label: 'Sign in',
                          expanded: false,
                          onPressed: () => context.push('/login'),
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
          children: [
            Expanded(
              child: MetricCard(
                label: 'Analyses',
                value: '${prof.profile?.analysesRun ?? history.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Comparisons',
                value: '${prof.profile?.comparisonsRun ?? 0}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'AI runs',
                value: '${prof.profile?.aiInsightsRun ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (prof.loading)
          const LoadingState(message: 'Loading profile…')
        else if (prof.error != null && prof.profile == null)
          ErrorState(
            message: prof.error!,
            onRetry: () => ref.read(profileProvider.notifier).load(),
          )
        else ...[
          const DevIQSectionLabel('CONNECTED ACCOUNTS'),
          const SizedBox(height: 8),
          Form(
            key: _form,
            child: DevIQCard(
              child: Column(
                children: [
                  DevIQTextField(
                    controller: _gh,
                    label: 'GitHub username',
                    hint: 'torvalds',
                    prefixIcon: Icons.hub_outlined,
                    monospace: true,
                  ),
                  const SizedBox(height: 10),
                  DevIQTextField(
                    controller: _lc,
                    label: 'LeetCode username',
                    hint: 'username',
                    prefixIcon: Icons.code_outlined,
                    monospace: true,
                  ),
                  const SizedBox(height: 10),
                  DevIQTextField(
                    controller: _cf,
                    label: 'Codeforces handle',
                    hint: 'tourist',
                    prefixIcon: Icons.emoji_events_outlined,
                    monospace: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const DevIQSectionLabel('DETAILS'),
          const SizedBox(height: 8),
          DevIQCard(
            child: Column(
              children: [
                DevIQTextField(
                  controller: _name,
                  label: 'Display name',
                  hint: 'Ada Lovelace',
                ),
                const SizedBox(height: 10),
                DevIQTextField(
                  controller: _bio,
                  label: 'Bio',
                  hint: 'Full-stack developer…',
                ),
                const SizedBox(height: 10),
                DevIQTextField(
                  controller: _site,
                  label: 'Website',
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                DevIQTextField(
                  controller: _loc,
                  label: 'Location',
                  hint: 'Berlin, DE',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DevIQButton(
            label: 'Save Profile',
            loading: prof.saving,
            onPressed: auth.status == AuthStatus.authenticated ? _save : null,
          ),
          if (auth.status != AuthStatus.authenticated)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Sign in to save your profile.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          const SizedBox(height: 8),
          DevIQSecondaryButton(
            label: 'Sync Profile',
            icon: Icons.sync,
            onPressed: auth.status == AuthStatus.authenticated
                ? () => ref.read(profileProvider.notifier).sync()
                : null,
          ),
        ],
        const SizedBox(height: 18),
        const DevIQSectionLabel('ACCOUNT'),
        const SizedBox(height: 8),
        DevIQCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, size: 19),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: auth.status == AuthStatus.authenticated
                    ? () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/home');
                        }
                      }
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  size: 19,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                onTap: auth.status == AuthStatus.authenticated
                    ? _confirmDelete
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
