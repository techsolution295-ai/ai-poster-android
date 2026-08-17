import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/text_layer_model.dart';
import '../../../providers/editor_controller.dart';

/// Quick actions for the currently selected layer — shown above the main toolbar.
class EditorSelectionBar extends StatelessWidget {
  final EditorController controller;
  final VoidCallback onEditText;
  final VoidCallback onEditColor;
  final VoidCallback onDelete;

  const EditorSelectionBar({
    super.key,
    required this.controller,
    required this.onEditText,
    required this.onEditColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final layer = controller.selected;
    if (layer == null) return const SizedBox.shrink();

    final isText = layer.type == LayerType.text;
    final label = isText
        ? (layer.text.isEmpty ? 'Text layer' : layer.text)
        : _layerLabel(layer.type);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (isText)
            _chip(
              icon: Icons.edit_rounded,
              label: 'Edit',
              primary: true,
              onTap: onEditText,
            ),
          _chip(icon: Icons.palette_outlined, label: 'Color', onTap: onEditColor),
          _iconBtn(Icons.flip_to_front, 'Front', controller.bringToFront),
          _iconBtn(Icons.flip_to_back, 'Back', controller.sendToBack),
          _iconBtn(Icons.delete_outline_rounded, 'Delete', onDelete, danger: true),
        ],
      ),
    );
  }

  String _layerLabel(LayerType type) {
    switch (type) {
      case LayerType.text:
        return 'Text';
      case LayerType.image:
        return 'Image';
      case LayerType.icon:
        return 'Icon';
      case LayerType.shape:
        return 'Shape';
    }
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: primary ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: primary ? AppColors.primary : AppColors.darkText),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary ? AppColors.primary : AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: danger ? AppColors.danger : AppColors.muted),
      ),
    );
  }
}
