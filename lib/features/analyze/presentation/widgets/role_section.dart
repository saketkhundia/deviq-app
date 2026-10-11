import 'package:flutter/material.dart';

import '../../../../core/utils/role_fit.dart';
import '../../../../shared/widgets/deviq_widgets.dart';
import '../../../../shared/widgets/liquid_glass.dart';

/// Developer role matching in liquid glass: frosted best-match lens
/// with a luminous initials badge and evidence chips, then all
/// matching roles with glowing per-role bars. Percentages are
/// client-side estimates from public signals — captioned as such,
/// never server scores.
class RoleSection extends StatelessWidget {
  const RoleSection({super.key, required this.fits});

  final List<RoleFit> fits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (fits.isEmpty) {
      return const EmptyState(
        icon: Icons.work_outline,
        title: 'No role signal yet',
        message: 'Connect a platform with languages or ratings to estimate role fit.',
      );
    }
    final best = fits.first;
    final bestColor = roleColor(best.role);
    return LiquidGlass(
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bestColor.withValues(alpha: 0.55)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bestColor.withValues(alpha: 0.22),
                      bestColor.withValues(alpha: 0.08),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bestColor.withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(
                  roleInitials(best.role),
                  style: TextStyle(
                    color: bestColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEST MATCH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        letterSpacing: 0.6,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      best.role,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.01,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (best.evidence.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in best.evidence)
                  _EvidenceLens(text: e, color: bestColor),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'All Matching Roles (${fits.length})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < fits.length; i++) ...[
            _RoleRow(fit: fits[i], showEvidence: i == 0),
            if (i != fits.length - 1) const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          Text(
            'Estimated from your public signals.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.fit, required this.showEvidence});

  final RoleFit fit;
  final bool showEvidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = roleColor(fit.role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              roleInitials(fit.role),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fit.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${fit.percent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: fit.percent >= 99.5
                    ? color
                    : theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GlassBar(value: fit.percent / 100, color: color, height: 6),
        if (showEvidence && fit.evidence.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in fit.evidence)
                _EvidenceLens(text: e, color: color, subtle: true),
            ],
          ),
        ],
      ],
    );
  }
}

class _EvidenceLens extends StatelessWidget {
  const _EvidenceLens({
    required this.text,
    required this.color,
    this.subtle = false,
  });

  final String text;
  final Color color;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: subtle
            ? LiquidGlassTokens.inset(dark)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subtle
              ? LiquidGlassTokens.edge(dark)
              : color.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: subtle ? theme.colorScheme.secondary : color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Two-letter role initials matching the web client.
String roleInitials(String role) => switch (role) {
  'Mobile Developer' => 'MB',
  'Competitive Programmer' => 'CP',
  'Backend Developer' => 'BE',
  'Application Developer' => 'AP',
  'ML/Data Engineer' => 'ML',
  'Full-Stack Developer' => 'FS',
  'Frontend Developer' => 'FE',
  'Security Engineer' => 'SE',
  'Embedded/IoT Developer' => 'HW',
  _ => role.isEmpty ? '?' : role.substring(0, 1).toUpperCase(),
};

/// Per-role bar color sampled from the web reference.
Color roleColor(String role) => switch (role) {
  'Mobile Developer' => const Color(0xFFE040FB),
  'Competitive Programmer' => const Color(0xFFF43F5E),
  'Backend Developer' => const Color(0xFF2DD4BF),
  'Application Developer' => const Color(0xFF22D3EE),
  'ML/Data Engineer' => const Color(0xFFA78BFA),
  'Full-Stack Developer' => const Color(0xFF22C55E),
  'Frontend Developer' => const Color(0xFF58A6FF),
  'Security Engineer' => const Color(0xFFFB923C),
  'Embedded/IoT Developer' => const Color(0xFF737373),
  _ => const Color(0xFFA3A3A3),
};
