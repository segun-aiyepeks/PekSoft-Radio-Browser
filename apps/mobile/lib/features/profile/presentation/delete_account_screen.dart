import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final AuthState authState = ref.watch(authViewModelProvider);
    final bool canDelete =
        !authState.isLoading &&
        _confirmController.text.trim().toUpperCase() == 'DELETE';

    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: colors.error),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is permanent',
                  style: AppTypography.title.copyWith(color: colors.error),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Deleting your account removes synced favourites, custom collections, and listening history. Active store subscriptions must still be cancelled in Google Play.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              authState.error!.userMessage,
              style: AppTypography.bodySmall.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            textField: true,
            label: 'Type DELETE to confirm account deletion',
            child: TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                hintText: 'DELETE',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.textPrimary,
              ),
              onPressed: canDelete
                  ? () async {
                      final bool ok = await ref
                          .read(authViewModelProvider.notifier)
                          .deleteAccount();
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deleted.')),
                        );
                        context.go('/profile');
                      }
                    }
                  : null,
              child: Text(
                authState.isLoading ? 'Deleting...' : 'Delete My Account',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
