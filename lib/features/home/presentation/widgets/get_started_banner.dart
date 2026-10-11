import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/auth_controller.dart';
import 'liquid_glass.dart';

/// Closing call-to-action rebuilt from scratch in liquid glass.
/// Deliberately subordinate to the hero: one calm frosted panel,
/// restrained title, single signal-glass action. Auth-aware:
/// signed-in users go to Analyze, guests to signup.
class GetStartedBanner extends ConsumerWidget {
  const GetStartedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authed = ref.watch(authProvider).status == AuthStatus.authenticated;
    void go() {
      if (authed) {
        context.go('/analyze');
      } else {
        context.push('/signup');
      }
    }

    return LiquidGlass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to measure your profile?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.01,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your accounts and get your score in seconds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final button = GlassPrimaryButton(
                label: authed ? 'Analyze my profile' : 'Get Started',
                icon: Icons.arrow_forward,
                onPressed: go,
              );
              if (c.maxWidth >= 560) {
                return Row(
                  children: [
                    const Spacer(),
                    SizedBox(width: 220, child: button),
                  ],
                );
              }
              return button;
            },
          ),
        ],
      ),
    );
  }
}
