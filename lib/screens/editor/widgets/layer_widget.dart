import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../engine/layer_view.dart';
import '../../../models/text_layer_model.dart';
import '../../../providers/editor_controller.dart';

/// Interactive layer — drag, pinch-zoom, rotate/resize/delete handles.
class LayerWidget extends StatefulWidget {
  final PosterLayer layer;
  final EditorController controller;
  final double canvasWidth;
  final double canvasHeight;
  final VoidCallback? onTextDoubleTap;

  const LayerWidget({
    super.key,
    required this.layer,
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
    this.onTextDoubleTap,
  });

  @override
  State<LayerWidget> createState() => _LayerWidgetState();
}

class _LayerWidgetState extends State<LayerWidget> {
  static const _handleTouch = 36.0;
  static const _handleSize = 28.0;
  final _layerKey = GlobalKey();

  double? _baseX;
  double? _baseY;
  double? _baseW;
  double? _baseH;
  double? _baseFont;
  double? _rotateStartPointerAngle;
  double? _rotateStartLayerAngle;

  EditorController get controller => widget.controller;
  PosterLayer get layer => widget.layer;
  double get canvasWidth => widget.canvasWidth;
  double get canvasHeight => widget.canvasHeight;
  bool get _selected => controller.selectedId == layer.id;

  Offset _localDelta(Offset delta) {
    final rot = layer.rotationRadians;
    if (rot.abs() < 0.001) return delta;
    final c = math.cos(-rot);
    final s = math.sin(-rot);
    return Offset(delta.dx * c - delta.dy * s, delta.dx * s + delta.dy * c);
  }

  double _pointerAngle(Offset globalPosition, RenderBox box) {
    final local = box.globalToLocal(globalPosition);
    final center = Offset(box.size.width / 2, box.size.height / 2);
    return math.atan2(local.dy - center.dy, local.dx - center.dx);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (layer.locked) return;
    if (controller.selectedId != layer.id) controller.select(layer.id);
    controller.pushHistory();
    _baseX = layer.x;
    _baseY = layer.y;
    _baseW = layer.width;
    _baseH = layer.height;
    _baseFont = layer.fontSizeFactor;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (layer.locked) return;
    if (_baseW == null) return;

    if (details.pointerCount >= 2) {
      controller.scaleLayerFromCenter(
        baseX: _baseX!,
        baseY: _baseY!,
        baseW: _baseW!,
        baseH: _baseH!,
        baseFontSize: _baseFont ?? layer.fontSizeFactor,
        scaleFactor: details.scale,
      );
      return;
    }

    controller.dragSelectedBy(
      details.focalPointDelta.dx / canvasWidth,
      details.focalPointDelta.dy / canvasHeight,
    );
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _baseX = null;
    _baseY = null;
    _baseW = null;
    _baseH = null;
    _baseFont = null;
  }

  @override
  Widget build(BuildContext context) {
    final left = layer.x * canvasWidth;
    final top = layer.y * canvasHeight;
    final width = layer.width * canvasWidth;
    final height = layer.height * canvasHeight;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: layer.rotationRadians,
        child: Stack(
          key: _layerKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => controller.select(layer.id),
                onDoubleTap: layer.type == LayerType.text ? widget.onTextDoubleTap : null,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                child: Opacity(
                  opacity: layer.opacity,
                  child: LayerView(layer: layer, canvasWidth: canvasWidth),
                ),
              ),
            ),
            if (_selected && !layer.locked) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              _deleteHandle(),
              _rotateHandle(),
              _resizeHandle(Alignment.bottomRight, 1, 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(IconData icon, {Color color = AppColors.primary}) {
    return Container(
      width: _handleSize,
      height: _handleSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Icon(icon, color: Colors.white, size: 15),
    );
  }

  Widget _deleteHandle() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: const Offset(-_handleTouch / 2, -_handleTouch / 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (controller.selectedId != layer.id) controller.select(layer.id);
              controller.deleteSelected();
            },
            child: SizedBox(
              width: _handleTouch,
              height: _handleTouch,
              child: Center(child: _buildHandle(Icons.close, color: AppColors.danger)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotateHandle() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topRight,
        child: Transform.translate(
          offset: const Offset(_handleTouch / 2, -_handleTouch / 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              if (controller.selectedId != layer.id) controller.select(layer.id);
              final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
              if (box == null) return;
              controller.pushHistory();
              _rotateStartPointerAngle = _pointerAngle(d.globalPosition, box);
              _rotateStartLayerAngle = layer.rotation;
            },
            onPanUpdate: (d) {
              if (_rotateStartPointerAngle == null || _rotateStartLayerAngle == null) return;
              final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
              if (box == null) return;
              final angle = _pointerAngle(d.globalPosition, box);
              final deltaDeg = (angle - _rotateStartPointerAngle!) * 180 / math.pi;
              controller.setLayerRotationDegrees(_rotateStartLayerAngle! + deltaDeg);
            },
            onPanEnd: (_) {
              _rotateStartPointerAngle = null;
              _rotateStartLayerAngle = null;
            },
            onPanCancel: () {
              _rotateStartPointerAngle = null;
              _rotateStartLayerAngle = null;
            },
            child: SizedBox(
              width: _handleTouch,
              height: _handleTouch,
              child: Center(
                child: _buildHandle(Icons.rotate_right, color: AppColors.secondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resizeHandle(Alignment alignment, int signX, int signY) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: Offset(signX * _handleTouch / 2, signY * _handleTouch / 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              if (controller.selectedId != layer.id) controller.select(layer.id);
              controller.pushHistory();
            },
            onPanUpdate: (d) {
              final local = _localDelta(d.delta);
              controller.resizeLayerLive(
                local.dx / canvasWidth,
                local.dy / canvasHeight,
              );
            },
            child: SizedBox(
              width: _handleTouch,
              height: _handleTouch,
              child: Center(child: _buildHandle(Icons.open_in_full)),
            ),
          ),
        ),
      ),
    );
  }
}
