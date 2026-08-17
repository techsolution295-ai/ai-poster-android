import 'package:flutter/material.dart';

/// Central palette for the app. Keeping colours here makes theming and
/// re-branding trivial and avoids magic hex values scattered across the UI.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C2BD9);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color darkText = Color(0xFF111827);

  static const Color surface = Colors.white;
  static const Color muted = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);

  /// Gradient used for headers and premium accents.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C2BD9), Color(0xFF9333EA)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );
}
