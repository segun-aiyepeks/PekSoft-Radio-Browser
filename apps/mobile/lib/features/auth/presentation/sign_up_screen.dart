import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bool ok = await ref
        .read(authViewModelProvider.notifier)
        .signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      context.push('/auth/verify-email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final AuthState authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (authState.error != null) ...[
              Text(
                authState.error!.userMessage,
                style: AppTypography.bodySmall.copyWith(color: colors.error),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Semantics(
              textField: true,
              label: 'Display name',
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              textField: true,
              label: 'Email address',
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email address'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              textField: true,
              label: 'Password',
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              textField: true,
              label: 'Confirm password',
              child: TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (v) => (v != _passwordController.text)
                    ? 'Passwords do not match'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: authState.isLoading
                  ? 'Creating account...'
                  : 'Create Account',
              onPressed: authState.isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
