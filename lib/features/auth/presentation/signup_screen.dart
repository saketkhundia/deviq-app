import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/score_utils.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import 'auth_controller.dart';

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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authProvider.notifier).signup(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _pw.text,
        );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(height: 8),
                    const DevIQSectionLabel('DEVELOPER ANALYTICS PLATFORM'),
                    const SizedBox(height: 10),
                    Text('Create your account',
                        style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.02)),
                    const SizedBox(height: 6),
                    Text('Measure your developer profile across every platform.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary)),
                    const SizedBox(height: 24),
                    DevIQTextField(
                      controller: _name,
                      label: 'Display name',
                      hint: 'Ada Lovelace',
                      prefixIcon: Icons.person_outlined,
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
                    DevIQTextField(
                      controller: _pw,
                      label: 'Password',
                      hint: 'Minimum 8 characters',
                      prefixIcon: Icons.lock_outlined,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          Validators.password(v, isSignup: true),
                    ),
                    const SizedBox(height: 12),
                    if (auth.error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(auth.error!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DevIQButton(
                        label: 'Create account',
                        loading: auth.working,
                        onPressed: _submit),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Already have an account?',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary)),
                        TextButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Sign in',
                              style: TextStyle(fontWeight: FontWeight.w700)),
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
    );
  }
}
