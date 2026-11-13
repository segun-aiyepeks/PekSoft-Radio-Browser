import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: mockSessionController,
        builder: (context, _) {
          final bool signedIn = mockSessionController.isSignedIn;
          final bool isPro = mockSessionController.isPro;

          return ListView(
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: AppSpacing.xl,
                          backgroundColor: colors.surfaceElevated,
                          child: Icon(
                            signedIn
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mockSessionController.userDisplayName,
                                style: AppTypography.title.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                signedIn
                                    ? mockSessionController.userEmail
                                    : 'Listening as guest (no account needed)',
                                style: AppTypography.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!signedIn)
                      PrimaryButton(
                        label: 'Sign In or Create Account',
                        icon: Icons.login_rounded,
                        onPressed: () => context.push('/auth'),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.touchTarget,
                        child: OutlinedButton(
                          onPressed: mockSessionController.signOutMock,
                          child: const Text('Sign Out (Mock)'),
                        ),
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
                      leading: Icon(
                        Icons.workspace_premium_rounded,
                        color: colors.accent,
                      ),
                      title: Text(
                        isPro ? 'PekSoft Pro Active' : 'Upgrade to PekSoft Pro',
                      ),
                      subtitle: Text(
                        isPro
                            ? 'Manage your mock subscription'
                            : 'Ad-free radio & unlimited favourites',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          context.push(isPro ? '/subscription' : '/paywall'),
                    ),
                    Divider(height: 1, color: colors.border),
                    ListTile(
                      minTileHeight: AppSpacing.touchTarget,
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      subtitle: const Text('Data saver, sleep timer, theme'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings'),
                    ),
                    Divider(height: 1, color: colors.border),
                    ListTile(
                      minTileHeight: AppSpacing.touchTarget,
                      leading: const Icon(Icons.credit_card_outlined),
                      title: const Text('Subscription Management'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/subscription'),
                    ),
                    Divider(height: 1, color: colors.border),
                    ListTile(
                      minTileHeight: AppSpacing.touchTarget,
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('About & Legal'),
                      subtitle: const Text('Station data by Radio Browser'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/about'),
                    ),
                    Divider(height: 1, color: colors.border),
                    ListTile(
                      minTileHeight: AppSpacing.touchTarget,
                      leading: const Icon(Icons.waving_hand_outlined),
                      title: const Text('Replay Welcome & Splash'),
                      subtitle: const Text('Preview onboarding flow'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/splash'),
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
                    SwitchListTile(
                      title: const Text('Simulate Offline Banner'),
                      subtitle: const Text('Preview offline mode across shell'),
                      value: mockSessionController.isOfflineSimulated,
                      onChanged: mockSessionController.setOfflineSimulated,
                    ),
                    Divider(height: 1, color: colors.border),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: appThemeController,
                      builder: (context, mode, _) {
                        return SwitchListTile(
                          title: const Text('Dark Theme'),
                          value: mode == ThemeMode.dark,
                          onChanged: (dark) => appThemeController.setMode(
                            dark ? ThemeMode.dark : ThemeMode.light,
                          ),
                        );
                      },
                    ),
                    if (kDebugMode) ...[
                      Divider(height: 1, color: colors.border),
                      ListTile(
                        minTileHeight: AppSpacing.touchTarget,
                        leading: Icon(
                          Icons.widgets_outlined,
                          color: colors.accent,
                        ),
                        title: const Text('Component Gallery (Dev)'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/gallery'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
