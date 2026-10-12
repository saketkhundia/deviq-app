import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../../data/models/analysis_models.dart';
import '../../../data/models/auth_models.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../../../shared/widgets/platform_icons.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../../shared/widgets/signal.dart';
import '../../analyze/presentation/analyze_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';

/// Profile in liquid glass, structured like the reference workspace:
/// cover banner with overlapping avatar, identity, stat lenses, about
/// and score panels, platform connections, editable details, recent
/// analyses with pagination, a progress chart, and account actions.
///
/// Every value is real: auth/profile state, persisted history, and
/// heuristic scores computed from stored history fields. Nothing is
/// fabricated; empty states say so plainly.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _detailsKey = GlobalKey();
  final _scroll = ScrollController();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _site = TextEditingController();
  final _loc = TextEditingController();
  final _gh = TextEditingController();
  final _lc = TextEditingController();
  final _cf = TextEditingController();
  bool _filled = false;
  int _shown = 5;
  int _chartTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(profileProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
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

  void _scrollToForm() {
    final ctx = _detailsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final prof = ref.watch(profileProvider);
    final history = ref.watch(historyProvider);
    final authed = auth.status == AuthStatus.authenticated;
    if (prof.profile != null) _fill(prof.profile!);

    final rawName = auth.user?.name ?? prof.profile?.displayName ?? '';
    final name = rawName.trim().isEmpty ? 'Guest' : rawName.trim();
    final email = auth.user?.email ?? '';
    final provider = auth.user?.provider ?? '';
    final bio = prof.profile?.bio ?? '';
    final location = prof.profile?.location ?? '';
    final website = prof.profile?.website ?? '';

    return DevIQPage(
      reserveNav: true,
      maxWidth: 960,
      controller: _scroll,
      children: [
        _CoverBanner(
          avatarUrl: auth.user?.avatar ?? prof.profile?.avatar,
          name: name,
          onEdit: _scrollToForm,
        ),
        const SizedBox(height: 44),
        _IdentityBlock(
          name: name,
          email: email,
          provider: provider,
          bio: bio,
          location: location,
          website: website,
          onEdit: _scrollToForm,
        ),
        const SizedBox(height: 28),
        _StatLenses(
          analyses: prof.profile?.analysesRun ?? history.length,
          comparisons: prof.profile?.comparisonsRun ?? 0,
          aiRuns: prof.profile?.aiInsightsRun ?? 0,
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final side = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AboutPanel(
                  bio: bio,
                  email: email,
                  location: location,
                  website: website,
                  onEdit: _scrollToForm,
                ),
                const SizedBox(height: 16),
                _ScorePanel(history: history),
              ],
            );
            final main = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlatformConnections(
                  gh: _gh,
                  lc: _lc,
                  cf: _cf,
                  saving: prof.saving,
                  onConnect: _save,
                ),
                const SizedBox(height: 16),
                if (prof.loading)
                  const LoadingState(message: 'Loading profile…')
                else if (prof.error != null && prof.profile == null)
                  ErrorState(
                    message: prof.error!,
                    onRetry: () => ref.read(profileProvider.notifier).load(),
                  )
                else ...[
                  _DetailsForm(
                    formKey: _form,
                    scrollKey: _detailsKey,
                    name: _name,
                    bio: _bio,
                    site: _site,
                    loc: _loc,
                    saving: prof.saving,
                    authed: authed,
                    onSave: _save,
                    onSync: () => ref.read(profileProvider.notifier).sync(),
                  ),
                  const SizedBox(height: 16),
                  _RecentAnalyses(
                    history: history,
                    shown: _shown,
                    onMore: () => setState(() => _shown += 10),
                  ),
                  const SizedBox(height: 16),
                  _ProgressPanel(
                    history: history,
                    tab: _chartTab,
                    onTab: (i) => setState(() => _chartTab = i),
                  ),
                ],
              ],
            );
            if (c.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: main),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: side),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                side,
                const SizedBox(height: 16),
                main,
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _AccountPanel(
          authed: authed,
          onLogout: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/home');
            }
          },
          onDelete: _confirmDelete,
        ),
      ],
    );
  }
}

/// Cover banner with a faint dot texture; the avatar overlaps its
/// bottom edge and Edit jumps to the details form.
class _CoverBanner extends StatelessWidget {
  const _CoverBanner({
    required this.avatarUrl,
    required this.name,
    required this.onEdit,
  });

  final String? avatarUrl;
  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        LiquidGlass(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          blur: 16,
          child: SizedBox(
            height: 132,
            width: double.infinity,
            child: CustomPaint(
              painter: _DotTexture(
                color: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            const Color(0xFF58A6FF).withValues(alpha: 0.10),
                            const Color(0xFF42E58B).withValues(alpha: 0.07),
                          ]
                        : [
                            const Color(0xFF58A6FF).withValues(alpha: 0.12),
                            const Color(0xFF0E9F5D).withValues(alpha: 0.08),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: -32,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: LiquidGlassTokens.edge(dark),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ProfileAvatar(url: avatarUrl, name: name, radius: 34),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: GlassGhostButton(
            label: 'Edit Profile',
            icon: Icons.edit_outlined,
            expanded: false,
            height: 36,
            fontSize: 12.5,
            onTap: onEdit,
          ),
        ),
      ],
    );
  }
}

class _DotTexture extends CustomPainter {
  _DotTexture({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 22.0;
    final paint = Paint()..color = color;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotTexture old) => old.color != color;
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.name,
    required this.email,
    required this.provider,
    required this.bio,
    required this.location,
    required this.website,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String provider;
  final String bio;
  final String location;
  final String website;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.01,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GlassGhostButton(
              label: 'Edit Profile',
              icon: Icons.edit_outlined,
              expanded: false,
              height: 38,
              fontSize: 13,
              onTap: onEdit,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            if (email.isNotEmpty)
              Text(
                email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondary,
                  fontSize: 13,
                ),
              ),
            if (provider.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  'Via ${_cap(provider)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: secondary,
                    fontSize: 11,
                  ),
                ),
              ),
            if (location.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place_outlined, size: 13, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            if (website.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.link_outlined,
                    size: 13,
                    color: DevIQColors.github,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      website,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DevIQColors.github,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            bio,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: secondary,
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _StatLenses extends StatelessWidget {
  const _StatLenses({
    required this.analyses,
    required this.comparisons,
    required this.aiRuns,
  });

  final int analyses;
  final int comparisons;
  final int aiRuns;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StatLens(
          icon: Icons.analytics_outlined,
          color: DevIQColors.github,
          value: '$analyses',
          label: 'Analyses Run',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatLens(
          icon: Icons.compare_arrows_outlined,
          color: DevIQColors.codeforces,
          value: '$comparisons',
          label: 'Comparisons',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatLens(
          icon: Icons.grid_view_outlined,
          color: DevIQColors.leetcode,
          value: '$aiRuns',
          label: 'AI Insights',
        ),
      ),
    ],
  );
}

class _StatLens extends StatelessWidget {
  const _StatLens({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiquidGlass(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      blur: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SignalType.tabular(
              theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.01,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({
    required this.bio,
    required this.email,
    required this.location,
    required this.website,
    required this.onEdit,
  });

  final String bio;
  final String email;
  final String location;
  final String website;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return LiquidGlass(
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ABOUT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: secondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: DevIQColors.github,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bio.isEmpty ? 'No bio yet.' : bio,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.55,
              color: bio.isEmpty ? secondary : null,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _AboutRow(icon: Icons.mail_outlined, text: email),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            _AboutRow(icon: Icons.place_outlined, text: location),
          ],
          if (website.isNotEmpty) ...[
            const SizedBox(height: 8),
            _AboutRow(
              icon: Icons.link_outlined,
              text: website,
              color: DevIQColors.github,
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: color ?? theme.colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? theme.colorScheme.secondary,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.history});

  final List<HistoryRecord> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return LiquidGlass(
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEVIQ SCORE',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 14),
          if (history.isEmpty) ...[
            const Center(child: _DashedRing()),
            const SizedBox(height: 12),
            Text(
              'Connect your platforms to get a unified developer score.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            GlassPrimaryButton(
              label: 'Run Analysis',
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/analyze'),
            ),
          ] else ...[
            Center(
              child: ScoreRing(
                score: history.first.score,
                color: DevIQColors.signalFor(dark),
                diameter: 120,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${ScoreUtils.verdict(history.first.score)} · Latest ${Formatters.date(history.first.date)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedRing extends StatelessWidget {
  const _DashedRing();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _DashedPainter(color: theme.dividerColor),
        child: Center(
          child: Text(
            '?',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.secondary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashes = 24;
    for (var i = 0; i < dashes; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: r),
        i / dashes * 6.2832,
        1 / dashes * 6.2832,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color;
}

class _PlatformConnections extends StatelessWidget {
  const _PlatformConnections({
    required this.gh,
    required this.lc,
    required this.cf,
    required this.saving,
    required this.onConnect,
  });

  final TextEditingController gh;
  final TextEditingController lc;
  final TextEditingController cf;
  final bool saving;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiquidGlass(
      padding: EdgeInsets.zero,
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Text(
              'PLATFORM CONNECTIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          _PlatformRow(
            platform: DevPlatform.github,
            name: 'GitHub',
            description: 'Code repositories & contribution activity',
            controller: gh,
            hint: 'Enter your GitHub username',
            saving: saving,
            onConnect: onConnect,
            last: false,
          ),
          _PlatformRow(
            platform: DevPlatform.leetcode,
            name: 'LeetCode',
            description: 'Coding challenge rankings & stats',
            controller: lc,
            hint: 'Enter your LeetCode username',
            saving: saving,
            onConnect: onConnect,
            last: false,
          ),
          _PlatformRow(
            platform: DevPlatform.codeforces,
            name: 'Codeforces',
            description: 'Competitive programming rating',
            controller: cf,
            hint: 'Enter your Codeforces handle',
            saving: saving,
            onConnect: onConnect,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({
    required this.platform,
    required this.name,
    required this.description,
    required this.controller,
    required this.hint,
    required this.saving,
    required this.onConnect,
    required this.last,
  });

  final DevPlatform platform;
  final String name;
  final String description;
  final TextEditingController controller;
  final String hint;
  final bool saving;
  final VoidCallback onConnect;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = PlatformIcons.accentOf(platform);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(color: LiquidGlassTokens.edge(dark)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  PlatformIcons.of(platform),
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GlassGhostButton(
                label: saving ? 'Saving…' : 'Connect',
                expanded: false,
                height: 38,
                fontSize: 13,
                onTap: onConnect,
              ),
            ],
          ),
          const SizedBox(height: 10),
          DevIQTextField(
            controller: controller,
            hint: hint,
            prefixIcon: PlatformIcons.of(platform),
            monospace: true,
          ),
        ],
      ),
    );
  }
}

class _DetailsForm extends StatelessWidget {
  const _DetailsForm({
    required this.formKey,
    required this.scrollKey,
    required this.name,
    required this.bio,
    required this.site,
    required this.loc,
    required this.saving,
    required this.authed,
    required this.onSave,
    required this.onSync,
  });

  final GlobalKey<FormState> formKey;
  final GlobalKey scrollKey;
  final TextEditingController name;
  final TextEditingController bio;
  final TextEditingController site;
  final TextEditingController loc;
  final bool saving;
  final bool authed;
  final VoidCallback onSave;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LiquidGlass(
      key: scrollKey,
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE DETAILS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: formKey,
            child: Column(
              children: [
                DevIQTextField(
                  controller: name,
                  label: 'Display name',
                  hint: 'Ada Lovelace',
                ),
                const SizedBox(height: 10),
                DevIQTextField(
                  controller: bio,
                  label: 'Bio',
                  hint: 'Full-stack developer…',
                ),
                const SizedBox(height: 10),
                DevIQTextField(
                  controller: site,
                  label: 'Website',
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                DevIQTextField(
                  controller: loc,
                  label: 'Location',
                  hint: 'Berlin, DE',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassPrimaryButton(
            label: 'Save Profile',
            loading: saving,
            onPressed: authed ? onSave : null,
          ),
          const SizedBox(height: 10),
          if (authed)
            GlassGhostButton(
              label: 'Sync Profile',
              icon: Icons.sync,
              onTap: onSync,
            )
          else
            Text(
              'Sign in to save your profile.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentAnalyses extends StatelessWidget {
  const _RecentAnalyses({
    required this.history,
    required this.shown,
    required this.onMore,
  });

  final List<HistoryRecord> history;
  final int shown;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = history.take(shown).toList();
    final remaining = history.length - visible.length;
    return LiquidGlass(
      padding: EdgeInsets.zero,
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'RECENT ANALYSES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                Text(
                  '${history.length} total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Text(
                'No analyses yet — run your first analysis to start the log.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  height: 1.55,
                ),
              ),
            )
          else
            for (var i = 0; i < visible.length; i++)
              _HistoryRow(record: visible[i], last: i == visible.length - 1),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: GlassGhostButton(
                label: 'Load More ($remaining remaining) →',
                icon: Icons.expand_more,
                onTap: onMore,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              remaining > 0 ? 0 : 4,
              18,
              16,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/analyze'),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Run New Analysis →',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DevIQColors.github,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, required this.last});

  final HistoryRecord record;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final secondary = theme.colorScheme.secondary;
    final scoreColor = DevIQColors.scoreColor(record.score);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(color: LiquidGlassTokens.edge(dark)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: DevIQColors.github,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Formatters.dateTime(record.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  record.score.toStringAsFixed(1),
                  style: SignalType.tabular(
                    TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (record.github.isNotEmpty)
                _UserChip(
                  platform: DevPlatform.github,
                  name: record.github,
                ),
              if (record.leetcode.isNotEmpty)
                _UserChip(
                  platform: DevPlatform.leetcode,
                  name: record.leetcode,
                ),
              if (record.codeforces.isNotEmpty)
                _UserChip(
                  platform: DevPlatform.codeforces,
                  name: record.codeforces,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondary,
                height: 1.55,
                fontSize: 12.5,
              ),
              children: [
                TextSpan(
                  text:
                      '${record.repos} repos ${record.stars} stars${record.language.isEmpty ? '' : ' ${record.language}'}',
                ),
                if (record.lcSolved > 0) ...[
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: '${record.lcEasy}',
                    style: const TextStyle(color: DevIQColors.success),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '${record.lcMedium}',
                    style: const TextStyle(color: DevIQColors.leetcode),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '${record.lcHard}',
                    style: const TextStyle(color: DevIQColors.error),
                  ),
                  TextSpan(text: ' = ${record.lcSolved} solved'),
                ],
                if (record.cfRating > 0)
                  TextSpan(
                    text:
                        '  ${record.cfRating}${record.cfRank.isEmpty ? '' : ' (${record.cfRank})'}',
                  ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.platform, required this.name});

  final DevPlatform platform;
  final String name;

  @override
  Widget build(BuildContext context) {
    final accent = PlatformIcons.accentOf(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PlatformIcons.of(platform), size: 12, color: accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.history,
    required this.tab,
    required this.onTab,
  });

  final List<HistoryRecord> history;
  final int tab;
  final ValueChanged<int> onTab;

  static const _tabs = ['Overall Score', 'GitHub', 'LeetCode', 'Codeforces'];

  List<double> _series() {
    List<double> values;
    switch (tab) {
      case 1:
        values = [
          for (final h in history)
            ScoreUtils.githubScore(
              repos: h.repos,
              stars: h.stars,
              languages: h.language.isEmpty ? 0 : 1,
            ),
        ];
      case 2:
        values = [
          for (final h in history)
            ScoreUtils.leetcodeScore(solved: h.lcSolved, hard: h.lcHard),
        ];
      case 3:
        values = [
          for (final h in history)
            ScoreUtils.codeforcesScore(
              rating: h.cfRating,
              contests: h.cfContests,
              solved: h.cfProblems,
            ),
        ];
      default:
        values = [for (final h in history) h.score];
    }
    return values.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final signal = DevIQColors.signalFor(dark);
    final series = _series();
    final maxPeak = series.isEmpty
        ? 0.0
        : series.reduce((a, b) => a > b ? a : b);
    final maxY = (maxPeak <= 0 ? 10.0 : maxPeak * 1.15);
    final first = series.isEmpty ? 0.0 : series.first;
    final latest = series.isEmpty ? 0.0 : series.last;
    final delta = latest - first;
    final deltaColor = delta.abs() < 0.05
        ? theme.colorScheme.secondary
        : (delta > 0 ? signal : DevIQColors.error);
    return LiquidGlass(
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_outlined,
                size: 15,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PROGRESS OVER TIME',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                GestureDetector(
                  onTap: () => onTab(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: i == tab
                          ? signal.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: i == tab
                            ? signal.withValues(alpha: 0.55)
                            : LiquidGlassTokens.edge(dark),
                      ),
                    ),
                    child: Text(
                      _tabs[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: i == tab
                            ? signal
                            : theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (series.isEmpty)
            Text(
              'No data yet — analyses you run will chart here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            )
          else ...[
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (series.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY / 4,
                    verticalInterval: series.length <= 1
                        ? 1
                        : (series.length - 1) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                      strokeWidth: 0.7,
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.35),
                      strokeWidth: 0.7,
                    ),
                  ),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < series.length; i++)
                          FlSpot(i.toDouble(), series[i]),
                      ],
                      isCurved: true,
                      barWidth: 2.5,
                      color: signal,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: signal.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${history.length} ${history.length == 1 ? 'analysis' : 'analyses'} · peak ${maxPeak.toStringAsFixed(1)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: LiquidGlassTokens.inset(dark),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: LiquidGlassTokens.edge(dark),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DeltaStat(
                      label: 'FIRST',
                      value: first.toStringAsFixed(1),
                    ),
                  ),
                  Expanded(
                    child: _DeltaStat(
                      label: 'LATEST',
                      value: latest.toStringAsFixed(1),
                    ),
                  ),
                  Expanded(
                    child: _DeltaStat(
                      label: 'CHANGE',
                      value:
                          '${delta.abs() < 0.05 ? '±' : (delta > 0 ? '↑ ' : '↓ ')}${delta.abs().toStringAsFixed(1)}',
                      color: deltaColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeltaStat extends StatelessWidget {
  const _DeltaStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            letterSpacing: 0.6,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SignalType.tabular(
            theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.authed,
    required this.onLogout,
    required this.onDelete,
  });

  final bool authed;
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      padding: EdgeInsets.zero,
      blur: 14,
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.history_outlined,
            label: 'History',
            onTap: () => context.push('/history'),
          ),
          _AccountRow(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => context.push('/settings'),
          ),
          _AccountRow(
            icon: Icons.logout,
            label: 'Logout',
            onTap: authed ? onLogout : () {},
          ),
          _AccountRow(
            icon: Icons.delete_outline,
            label: 'Delete account',
            danger: true,
            last: true,
            onTap: authed ? onDelete : () {},
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.last = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(color: LiquidGlassTokens.edge(dark)),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 19,
          color: danger ? Colors.red : theme.colorScheme.secondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: danger ? Colors.red : null,
          ),
        ),
        trailing: danger
            ? null
            : Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
      ),
    );
  }
}
