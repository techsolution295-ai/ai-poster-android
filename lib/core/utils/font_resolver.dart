import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Resolves a Google Font family name to a [TextStyle]. Wrapping GoogleFonts in
/// a try/catch means an unknown / offline font falls back gracefully instead of
/// throwing at render time.
class FontResolver {
  FontResolver._();

  /// A curated list of free Google Fonts offered in the editor font picker.
  static const List<String> curatedFonts = [
    'Poppins',
    'Roboto',
    'Montserrat',
    'Oswald',
    'Lato',
    'Playfair Display',
    'Merriweather',
    'Bebas Neue',
    'Anton',
    'Pacifico',
    'Lobster',
    'Raleway',
    'Nunito',
    'Cairo', // supports Arabic (useful for Umrah posters)
    'Amiri', // Arabic serif
  ];

  static TextStyle style(String? family, {TextStyle? base}) {
    final fallback = base ?? const TextStyle();
    if (family == null || family.isEmpty) return fallback;
    try {
      return GoogleFonts.getFont(family, textStyle: fallback);
    } catch (_) {
      // Unknown family or offline: keep the base style.
      return fallback;
    }
  }
}
