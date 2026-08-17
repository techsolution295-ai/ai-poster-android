import 'package:flutter/material.dart';

/// Helpers for converting between [Color] and the hex strings we persist in
/// Firestore / design JSON.
class ColorUtils {
  ColorUtils._();

  /// Parses `#RRGGBB` or `#AARRGGBB` (with or without leading `#`).
  /// Falls back to [fallback] on any parse error.
  static Color fromHex(String? hex, {Color fallback = Colors.black}) {
    if (hex == null || hex.isEmpty) return fallback;
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;
    final intVal = int.tryParse(value, radix: 16);
    if (intVal == null) return fallback;
    return Color(intVal);
  }

  /// Serialises a colour back to `#AARRGGBB`.
  static String toHex(Color color, {bool includeAlpha = true}) {
    // ignore: deprecated_member_use
    final argb = color.value & 0xFFFFFFFF;
    final str = argb.toRadixString(16).padLeft(8, '0').toUpperCase();
    return includeAlpha ? '#$str' : '#${str.substring(2)}';
  }

  /// Returns black or white depending on which contrasts better with [bg].
  static Color contrastOn(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
