import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/score_utils.dart';
import '../../../../shared/widgets/deviq_widgets.dart';
import '../../../../shared/widgets/platform_icons.dart';
import '../../../app/providers/app_providers.dart';

/// Username inputs + Run Analysis. Owns controllers, prefill and
/// validation; reports submitted values upward. Button disables while
/// [loading] to prevent duplicate submissions.
class UsernameForm extends ConsumerStatefulWidget {
  const UsernameForm({super.key, required this.loading, required this.onRun});

  final bool loading;
  final void Function(String github, String leetcode, String codeforces) onRun;

  @override
  ConsumerState<UsernameForm> createState() => _UsernameFormState();
}

class _UsernameFormState extends ConsumerState<UsernameForm> {
  final _form = GlobalKey<FormState>();
  final _gh = TextEditingController();
  final _lc = TextEditingController();
  final _cf = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _gh.dispose();
    _lc.dispose();
    _cf.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    if (_prefilled) return;
    _prefilled = true;
    final last = await ref.read(prefsStoreProvider).lastUsernames();
    if (!mounted) return;
    setState(() {
      // Never clobber text the user already typed (slow storage +
      // fast typist would otherwise erase their input).
      if (_gh.text.isEmpty) _gh.text = last['github'] ?? '';
      if (_lc.text.isEmpty) _lc.text = last['leetcode'] ?? '';
      if (_cf.text.isEmpty) _cf.text = last['codeforces'] ?? '';
    });
  }

  void _submit() {
    if (widget.loading) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.onRun(_gh.text, _lc.text, _cf.text);
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    return DevIQCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DevIQTextField(
              controller: _gh,
              label: 'GITHUB',
              hint: 'torvalds',
              prefixIcon: PlatformIcons.of(DevPlatform.github),
              monospace: true,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.username(v, required: false),
            ),
            const SizedBox(height: 12),
            DevIQTextField(
              controller: _lc,
              label: 'LEETCODE',
              hint: 'leetcode_username',
              prefixIcon: PlatformIcons.of(DevPlatform.leetcode),
              monospace: true,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.username(v, required: false),
            ),
            const SizedBox(height: 12),
            DevIQTextField(
              controller: _cf,
              label: 'CODEFORCES',
              hint: 'tourist',
              prefixIcon: PlatformIcons.of(DevPlatform.codeforces),
              monospace: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => Validators.username(v, required: false),
            ),
            const SizedBox(height: 16),
            DevIQButton(
              label: 'Run Analysis',
              icon: Icons.play_arrow,
              loading: widget.loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
