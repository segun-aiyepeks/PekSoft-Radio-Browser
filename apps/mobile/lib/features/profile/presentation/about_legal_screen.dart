import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

class AboutLegalScreen extends StatelessWidget {
  const AboutLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('About & Legal')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PekSoft Radio Browser',
                  style: AppTypography.h2.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Version 1.0.0 · Phase 1 Mobile UI (Mock Data)',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Station data by Radio Browser (radio-browser.info). Live audio streams are served directly by their respective broadcasters.',
                  style: AppTypography.body.copyWith(color: colors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              children: [
                ListTile(
                  minTileHeight: AppSpacing.touchTarget,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  subtitle: const Text(
                    'Stream directory & Pro subscription terms',
                  ),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terms of Service preview (mock).'),
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.border),
                ListTile(
                  minTileHeight: AppSpacing.touchTarget,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Guest-first, minimal telemetry'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy Policy preview (mock).'),
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.border),
                ListTile(
                  minTileHeight: AppSpacing.touchTarget,
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Open-Source Licences'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'PekSoft Radio Browser',
                    applicationVersion: '1.0.0 (Phase 1)',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
