import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/auth_controller.dart';
import '../../../../shared/widgets/deviq_widgets.dart';

/// Wide CTA banner. Text-left/button-right on wide layouts, stacked on
/// phones. Auth-aware: signed-in users go to Analyze, guests to signup.
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

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to measure your profile?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect your accounts and get your score in seconds.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
    final button = DevIQButton(
      label: 'Get Started',
      icon: Icons.arrow_forward,
      onPressed: go,
    );
    return DevIQCard(
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 560) {
            return Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                SizedBox(width: 180, child: button),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 16), button],
          );
        },
      ),
    );
  }
}
