import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A single tool entry in the editor toolbar.
class EditorTool {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const EditorTool({required this.icon, required this.label, required this.onTap});
}

/// Compact horizontal toolbar grouped for the poster editor.
class EditorToolbar extends StatelessWidget {
  final List<EditorTool> tools;
  const EditorToolbar({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: tools.length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, i) => _ToolButton(tool: tools[i]),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final EditorTool tool;
  const _ToolButton({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: tool.onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tool.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                tool.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
