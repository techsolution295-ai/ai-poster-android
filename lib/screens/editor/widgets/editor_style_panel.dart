import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/font_resolver.dart';
import '../../../models/text_layer_model.dart';
import '../../../providers/editor_controller.dart';

/// White panel above the toolbar for font family and text formatting.
class EditorStylePanel extends StatelessWidget {
  final EditorController controller;
  final PosterLayer layer;

  const EditorStylePanel({
    super.key,
    required this.controller,
    required this.layer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _chip(
                icon: Icons.format_bold,
                label: 'Bold',
                active: layer.bold,
                onTap: controller.toggleBold,
              ),
              const SizedBox(width: 8),
              _chip(
                icon: Icons.format_italic,
                label: 'Italic',
                active: layer.italic,
                onTap: controller.toggleItalic,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: FontResolver.curatedFonts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final font = FontResolver.curatedFonts[i];
                final selected = layer.fontFamily == font;
                return GestureDetector(
                  onTap: () => controller.setFont(font),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      font,
                      style: FontResolver.style(
                        font,
                        base: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primary : AppColors.darkText,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.darkText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
