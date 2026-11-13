import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/routing/app_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';

void main() {
  runApp(const PekSoftRadioApp());
}

class PekSoftRadioApp extends StatelessWidget {
  const PekSoftRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeController,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'PekSoft Radio Browser',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: appRouter,
        );
      },
    );
  }
}
