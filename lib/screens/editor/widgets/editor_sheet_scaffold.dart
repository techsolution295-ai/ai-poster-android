import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shared bottom-sheet chrome: drag handle, title row, and height limit.
class EditorSheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onDone;
  final double maxHeightFraction;

  const EditorSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onDone,
    this.maxHeightFraction = 0.52,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFraction;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: onDone ?? () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
