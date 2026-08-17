import 'package:flutter/material.dart';

import '../../../engine/poster_canvas.dart';
import '../../../providers/editor_controller.dart';
import 'layer_widget.dart';

/// The interactive editing surface with a subtle checkerboard behind the poster.
class EditorCanvas extends StatelessWidget {
  final EditorController controller;
  final GlobalKey boundaryKey;
  final VoidCallback? onTextLayerTap;
  final VoidCallback? onEmptyTap;

  const EditorCanvas({
    super.key,
    required this.controller,
    required this.boundaryKey,
    this.onTextLayerTap,
    this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    final design = controller.design;
    return Center(
      child: AspectRatio(
        aspectRatio: design.aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: RepaintBoundary(
              key: boundaryKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            onEmptyTap?.call();
                            controller.deselect();
                          },
                          child: const _Checkerboard(),
                        ),
                      ),
                      Positioned.fill(
                        child: ClipRect(
                          child: Stack(
                            children: [
                              Positioned.fill(child: PosterBackground(design: design)),
                              Positioned.fill(child: PosterOverlay(design: design)),
                              for (final layer in design.layers)
                                LayerWidget(
                                  layer: layer,
                                  controller: controller,
                                  canvasWidth: w,
                                  canvasHeight: h,
                                  onTextDoubleTap: onTextLayerTap,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Checkerboard extends StatelessWidget {
  const _Checkerboard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CheckerboardPainter());
  }
}

class _CheckerboardPainter extends CustomPainter {
  static const _light = Color(0xFF2A2F3A);
  static const _dark = Color(0xFF232833);
  static const _cell = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var y = 0.0; y < size.height; y += _cell) {
      for (var x = 0.0; x < size.width; x += _cell) {
        final isLight = ((x / _cell).floor() + (y / _cell).floor()) % 2 == 0;
        paint.color = isLight ? _light : _dark;
        canvas.drawRect(Rect.fromLTWH(x, y, _cell, _cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
