import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/mock/mock.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool canDelete =
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
                  'This action is permanent (Mock)',
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
                  ? () {
                      mockSessionController.signOutMock();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deleted (mock).'),
                        ),
                      );
                      context.go('/profile');
                    }
                  : null,
              child: const Text('Delete My Account (Mock)'),
            ),
          ),
        ],
      ),
    );
  }
}
