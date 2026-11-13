import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentHover,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentHover;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  static const AppSemanticColors dark = AppSemanticColors(
    background: AppDarkColors.background,
    surface: AppDarkColors.surface,
    surfaceElevated: AppDarkColors.surfaceElevated,
    surfaceMuted: AppDarkColors.surfaceMuted,
    border: AppDarkColors.border,
    textPrimary: AppDarkColors.textPrimary,
    textSecondary: AppDarkColors.textSecondary,
    textMuted: AppDarkColors.textMuted,
    accent: AppDarkColors.accent,
    accentHover: AppDarkColors.accentHover,
    onAccent: AppDarkColors.onAccent,
    success: AppDarkColors.success,
    warning: AppDarkColors.warning,
    error: AppDarkColors.error,
    info: AppDarkColors.info,
  );

  static const AppSemanticColors light = AppSemanticColors(
    background: AppLightColors.background,
    surface: AppLightColors.surface,
    surfaceElevated: AppLightColors.surfaceElevated,
    surfaceMuted: AppLightColors.surfaceMuted,
    border: AppLightColors.border,
    textPrimary: AppLightColors.textPrimary,
    textSecondary: AppLightColors.textSecondary,
    textMuted: AppLightColors.textMuted,
    accent: AppLightColors.accent,
    accentHover: AppLightColors.accentHover,
    onAccent: AppLightColors.onAccent,
    success: AppLightColors.success,
    warning: AppLightColors.warning,
    error: AppLightColors.error,
    info: AppLightColors.info,
  );

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentHover,
    Color? onAccent,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppSemanticColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.dark;
}

abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, AppSemanticColors.dark);

  static ThemeData light() => _build(Brightness.light, AppSemanticColors.light);

  static ThemeData _build(Brightness brightness, AppSemanticColors colors) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.surfaceElevated,
      onSecondary: colors.textPrimary,
      error: colors.error,
      onError: colors.onAccent,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.border,
      surfaceContainerHighest: colors.surfaceElevated,
    );

    final textTheme = TextTheme(
      displaySmall: AppTypography.display.copyWith(color: colors.textPrimary),
      headlineLarge: AppTypography.h1.copyWith(color: colors.textPrimary),
      headlineMedium: AppTypography.h2.copyWith(color: colors.textPrimary),
      headlineSmall: AppTypography.h3.copyWith(color: colors.textPrimary),
      titleMedium: AppTypography.title.copyWith(color: colors.textPrimary),
      bodyLarge: AppTypography.body.copyWith(color: colors.textPrimary),
      bodyMedium: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
      labelLarge: AppTypography.label.copyWith(color: colors.textPrimary),
      bodySmall: AppTypography.caption.copyWith(color: colors.textMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.h2.copyWith(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accent.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.accent : colors.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption.copyWith(
            color: selected ? colors.accent : colors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: colors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
