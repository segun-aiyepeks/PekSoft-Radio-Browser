import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PekSoft Radio'),
        actions: [
          if (kDebugMode)
            Semantics(
              button: true,
              label: 'Open component gallery',
              child: SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: IconButton(
                  tooltip: 'Component Gallery (Dev)',
                  icon: Icon(Icons.widgets_outlined, color: colors.accent),
                  onPressed: () => context.push('/gallery'),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: const [
          SectionHeader(title: 'Home'),
          EmptyState(
            title: 'Home shell ready',
            message:
                'Discovery screens and mock stations arrive in Milestones 1.2 & 1.3.',
            icon: Icons.radio_rounded,
          ),
        ],
      ),
    );
  }
}
