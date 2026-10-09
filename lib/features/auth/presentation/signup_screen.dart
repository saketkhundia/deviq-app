import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/score_utils.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import 'auth_controller.dart';
import 'login_screen.dart' show AuthWordmark, AuthErrorBanner, PasswordField;

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _match(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _pw.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    final ctrl = ref.read(authProvider.notifier);
    if (ctrl.working) return; // prevent duplicate submissions
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ctrl.signup(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _pw.text,
    );
    // The backend signs the new account in directly (success payload
    // carries access_token; no verification step exists). Failure stays
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
                        'Create your account',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'One account for your unified score, history and AI insights.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DevIQTextField(
                        controller: _name,
                        label: 'Full name',
                        hint: 'Ada Lovelace',
                        prefixIcon: Icons.person_outlined,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
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
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.password(v, isSignup: true),
                        helper: 'Minimum 8 characters.',
                      ),
                      const SizedBox(height: 12),
                      PasswordField(
                        controller: _confirm,
                        label: 'Confirm password',
                        obscure: _obscure2,
                        onToggle: () => setState(() => _obscure2 = !_obscure2),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: _match,
                      ),
                      // NOTE: no Terms/Privacy links — the product has no
                      // published policy URLs to point at (see report).
                      const SizedBox(height: 4),
                      if (auth.error != null) ...[
                        AuthErrorBanner(message: auth.error!),
                        const SizedBox(height: 12),
                      ] else
                        const SizedBox(height: 12),
                      DevIQButton(
                        label: 'Create Account',
                        loading: auth.working,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          TextButton(
                            onPressed: auth.working
                                ? null
                                : () => context.push('/login'),
                            child: const Text(
                              'Sign in',
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
