import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/score_utils.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import 'auth_controller.dart';

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
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authProvider.notifier).login(
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
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(height: 8),
                    const DevIQSectionLabel('DEVELOPER ANALYTICS PLATFORM'),
                    const SizedBox(height: 10),
                    Text('Welcome back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.02)),
                    const SizedBox(height: 6),
                    Text('Sign in to sync your profile, history and AI insights.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary)),
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
                    DevIQTextField(
                      controller: _pw,
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outlined,
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => Validators.password(v),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                        child: Text(_obscure ? 'Show' : 'Hide'),
                      ),
                    ),
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
                        label: 'Sign in',
                        loading: auth.working,
                        onPressed: _submit),
                    const SizedBox(height: 10),
                    DevIQSecondaryButton(
                      label: 'Continue without account',
                      onPressed: () => context.go('/home'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('New to DevIQ?',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary)),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: const Text('Create account',
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
