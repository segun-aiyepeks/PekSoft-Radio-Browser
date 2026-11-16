import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:peksoft_radio/features/profile/presentation/view_models/settings_view_model.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/presentation/view_models/subscription_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final AuthState authState = ref.watch(authViewModelProvider);
    final AsyncValue<SubscriptionState> subAsync = ref.watch(
      subscriptionViewModelProvider,
    );
    final AsyncValue<SettingsState> settingsAsync = ref.watch(
      settingsViewModelProvider,
    );

    final bool signedIn = authState.isAuthenticated;
    final bool isPro =
        subAsync.asData?.value.entitlement.tier == EntitlementTier.pro;
    final bool offlineSim =
        settingsAsync.asData?.value.isOfflineSimulated ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                            signedIn
                                ? (authState.displayName ?? 'Listener')
                                : 'Guest Listener',
                            style: AppTypography.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            signedIn
                                ? (authState.userEmail ?? '')
                                : 'Listening as guest (no account needed)',
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          if (signedIn && !authState.emailVerified)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xxs,
                              ),
                              child: GestureDetector(
                                onTap: () => context.push('/auth/verify-email'),
                                child: Text(
                                  'Email not verified · Tap to verify',
                                  style: AppTypography.caption.copyWith(
                                    color: colors.accent,
                                  ),
                                ),
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
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSpacing.touchTarget,
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () async {
                                    final bool ok = await ref
                                        .read(authViewModelProvider.notifier)
                                        .syncNow();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Library synced.'
                                              : 'Sync failed. Try again later.',
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('Sync Now'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SizedBox(
                          height: AppSpacing.touchTarget,
                          child: OutlinedButton(
                            onPressed: authState.isLoading
                                ? null
                                : () => ref
                                      .read(authViewModelProvider.notifier)
                                      .signOut(),
                            child: const Text('Sign Out'),
                          ),
                        ),
                      ),
                    ],
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
                    isPro ? 'PekSoft Plus Active' : 'Upgrade to PekSoft Plus',
                  ),
                  subtitle: Text(
                    isPro
                        ? 'Manage your subscription'
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
                if (signedIn) ...[
                  Divider(height: 1, color: colors.border),
                  ListTile(
                    minTileHeight: AppSpacing.touchTarget,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(color: colors.error),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/delete-account'),
                  ),
                ],
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
                  value: offlineSim,
                  onChanged: (_) => ref
                      .read(settingsViewModelProvider.notifier)
                      .toggleOfflineSimulated(),
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
                    leading: Icon(Icons.widgets_outlined, color: colors.accent),
                    title: const Text('Component Gallery (Dev)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/gallery'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
