import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

/// Root widget: sets up theming and the initial route (Splash → Home).
class PosterMakerApp extends StatelessWidget {
  const PosterMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppEntry(),
    );
  }
}
