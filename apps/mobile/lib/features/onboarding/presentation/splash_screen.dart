import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/onboarding/presentation/view_models/splash_view_model.dart';

/// Clean Splash screen showing only the singular centered PekSoft logo (no box/border)
/// and `developed by aiyepeks` at the bottom.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();
    _autoNavTimer = Timer(const Duration(seconds: 2), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    String destination = '/welcome';
    try {
      final splashState = await ref.read(splashViewModelProvider.future);
      destination = splashState.destinationRoute;
    } catch (_) {
      destination =
          ref.read(splashViewModelProvider).value?.destinationRoute ??
              '/welcome';
    }
    if (!mounted) return;
    GoRouter.maybeOf(context)?.go(destination);
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Start loading saved onboarding settings immediately while Splash renders.
    ref.watch(splashViewModelProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _autoNavTimer?.cancel();
            _navigateNext();
          },
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: 'PekSoft Radio Browser logo',
                      child: const PekSoftSignalLoader(
                        size: 136,
                        label: null,
                        showBackground: false,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'PekSoft Radio Browser',
                      style: AppTypography.h2.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Text(
                  '© ${DateTime.now().year} developed by aiyepeks',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
