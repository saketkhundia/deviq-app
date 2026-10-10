import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/deviq_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../../shared/widgets/deviq_widgets.dart';
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
        color: DevIQColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: DevIQColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: DevIQColors.error,
          height: 1.5,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthWordmark(),
                      const SizedBox(height: 28),
                      Text(
                        'Welcome back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your developer journey continues here.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DevIQTextField(
                        controller: _email,
                        label: 'Email',
                        hint: 'you@example.com',
                        prefixIcon: Icons.mail_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 12),
                      PasswordField(
                        controller: _pw,
                        label: 'Password',
                        obscure: _obscure,
                        onToggle: () => setState(() => _obscure = !_obscure),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) => Validators.password(v),
                      ),
                      // NOTE: no "Forgot password" — the backend exposes
                      // no recovery endpoint (see phase report). A link
                      // would be a fake flow.
                      const SizedBox(height: 4),
                      // AnimatedSize keeps error appearance smooth instead
                      // of jumping the form below it.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: auth.error != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AuthErrorBanner(message: auth.error!),
                                  const SizedBox(height: 12),
                                ],
                              )
                            : const SizedBox(
                                width: double.infinity,
                                height: 12,
                              ),
                      ),
                      DevIQButton(
                        label: 'Sign In',
                        loading: auth.working,
                        onPressed: _submit,
                      ),
                      // NOTE: no social buttons — POST /auth/oauth needs
                      // a web OAuth code flow with no documented mobile
                      // redirect/PKCE support (see phase report).
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
                            onPressed: auth.working
                                ? null
                                : () => context.push('/signup'),
                            child: const Text(
                              'Create account',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          <= 1 => DevIQColors.error,
          2 => DevIQColors.warning,
          3 => DevIQColors.github,
          _ => DevIQColors.success,
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
                    color: i < score ? color : theme.dividerColor,
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

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.password],
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined, size: 17),
            suffixIcon: IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 19,
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ],
    );
  }
}
