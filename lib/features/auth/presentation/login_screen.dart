import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/score_utils.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../../shared/widgets/glass.dart';
import 'auth_controller.dart';

/// DevIQ wordmark header shared by auth screens.
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const DevIQLogo(size: 34, radius: 10),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DevIQ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Developer Analytics Platform',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Inline server/auth error banner. Never shows raw transport details
/// (those are mapped to human copy before reaching the UI).
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuthTokens.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthTokens.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AuthTokens.error,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Restrained password-strength meter (advisory only — the backend
/// enforces just the 8-character minimum, and validation is unchanged).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, v, _) {
        if (v.text.isEmpty) return const SizedBox.shrink();
        final score = Validators.passwordStrength(v.text);
        final color = switch (score) {
          <= 1 => AuthTokens.error,
          2 => AuthTokens.warning,
          3 => const Color(0xFF58A6FF),
          _ => AuthTokens.success,
        };
        return Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < score
                        ? color
                        : theme.dividerColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              Validators.passwordStrengthLabel(score),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Auth page scaffold: spec background per brightness, safe area,
/// centered 420px column, smooth keyboard scrolling.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark
          ? AuthTokens.darkBackground
          : AuthTokens.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(child: Column(children: children)),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ctrl = ref.read(authProvider.notifier);
    if (ctrl.working) return; // prevent duplicate submissions
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ctrl.login(email: _email.text.trim(), password: _pw.text);
    // Success navigates via the router's auth redirect; failure stays
    // here with the inline banner. Input is preserved either way.
    if (ok && mounted) context.go('/home');
  }

  Future<void> _google() async {
    final ctrl = ref.read(authProvider.notifier);
    if (ctrl.working) return;
    final ok = await ctrl.signInWithGoogle();
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    return AuthScaffold(
      children: [
        const AuthWordmark(),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Welcome back.',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Your developer journey continues here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _email,
                label: 'Email address',
                hint: 'you@example.com',
                prefixIcon: Icons.mail_outlined,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _pw,
                label: 'Password',
                hint: '••••••••',
                prefixIcon: Icons.lock_outlined,
                obscure: _obscure,
                keyboardType: TextInputType.visiblePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => Validators.password(v),
                suffix: VisibilityToggle(
                  obscured: _obscure,
                  onTap: () => setState(() => _obscure = !_obscure),
                ),
              ),
              // NOTE: no "Forgot password" — the backend exposes
              // no recovery endpoint (see phase report). A link
              // would be a fake flow.
              const SizedBox(height: 4),
              // Smooth error appearance instead of a layout jump.
              AnimatedSize(
                duration: AuthTokens.motion(context, AuthTokens.fast),
                curve: Curves.easeOut,
                child: auth.error != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthErrorBanner(message: auth.error!),
                          const SizedBox(height: 12),
                        ],
                      )
                    : const SizedBox(width: double.infinity, height: 12),
              ),
              PrimaryActionButton(
                label: 'Sign In',
                loading: auth.working,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              const OrDivider(),
              const SizedBox(height: 12),
              GoogleSignInButton(
                loading: auth.working,
                onPressed: auth.working ? null : _google,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'New to DevIQ?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            TextButton(
              onPressed: auth.working ? null : () => context.push('/signup'),
              child: const Text(
                'Create account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
