import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/color_utils.dart';

/// A compact palette-based colour picker. Returns the chosen colour as an
/// `#AARRGGBB` hex string via [onSelected].
class ColorSwatchPicker extends StatelessWidget {
  final String? selectedHex;
  final ValueChanged<String> onSelected;
  final bool includeTransparent;

  const ColorSwatchPicker({
    super.key,
    this.selectedHex,
    required this.onSelected,
    this.includeTransparent = false,
  });

  static const List<Color> _palette = [
    Colors.white,
    Colors.black,
    AppColors.primary,
    Color(0xFF9333EA),
    AppColors.secondary,
    Color(0xFFEF4444),
    Color(0xFF16A34A),
    Color(0xFF0EA5E9),
    Color(0xFFFACC15),
    Color(0xFFEC4899),
    Color(0xFF111827),
    Color(0xFF64748B),
    Color(0xFFFDE68A),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
    Color(0xFF065F46),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = [
      if (includeTransparent) Colors.transparent,
      ..._palette,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colors)
          Builder(builder: (_) {
            final hex = ColorUtils.toHex(c);
            final isSel = selectedHex != null &&
                hex.toUpperCase() == selectedHex!.toUpperCase();
            return GestureDetector(
            onTap: () => onSelected(hex),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.divider,
                  width: isSel ? 3 : 1,
                ),
              ),
              child: c == Colors.transparent
                  ? const Icon(Icons.block, size: 18, color: AppColors.muted)
                  : null,
            ),
          );
          }),
      ],
    );
  }
}
