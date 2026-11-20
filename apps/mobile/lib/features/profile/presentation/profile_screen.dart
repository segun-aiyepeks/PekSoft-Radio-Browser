import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';
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

    final bool signedIn = authState.isAuthenticated;
    final bool isPro =
        subAsync.asData?.value.entitlement.tier == EntitlementTier.pro;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
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
                        color: colors.accentText,
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
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () =>
                                    context.push('/auth/verify-email'),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.accentText,
                                  minimumSize: const Size(
                                    AppSpacing.touchTarget,
                                    AppSpacing.touchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.padded,
                                ),
                                child: const Text(
                                  'Email not verified · Tap to verify',
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSpacing.touchTarget,
                          ),
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSpacing.touchTarget,
                          ),
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
                  subtitle: Text(
                    'Station data by Radio Browser · © ${DateTime.now().year} developed by aiyepeks',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/about'),
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
            child: ValueListenableBuilder<ThemeMode>(
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
          ),
        ],
          ),
        ),
      ),
    );
  }
}
