import 'package:flutter/material.dart';

import '../core/utils/font_resolver.dart';

/// Provides the list of free Google Fonts offered in the editor and resolves a
/// family name to a [TextStyle]. Backed by the `google_fonts` package, so fonts
/// are fetched on demand and cached — no manual font asset management.
class FontService {
  FontService._();
  static final FontService instance = FontService._();

  List<String> get fonts => FontResolver.curatedFonts;

  TextStyle style(String family, {TextStyle? base}) =>
      FontResolver.style(family, base: base);
}
