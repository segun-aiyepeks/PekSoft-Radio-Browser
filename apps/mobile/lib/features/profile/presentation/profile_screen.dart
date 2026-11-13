import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const EmptyState(
            title: 'Profile shell ready',
            message:
                'Account, Settings, Paywall, and Legal screens arrive in Milestone 1.5.',
            icon: Icons.person_outline_rounded,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Open Component Gallery (Dev)',
              icon: Icons.widgets_outlined,
              onPressed: () => context.push('/gallery'),
            ),
          ],
        ],
      ),
    );
  }
}
