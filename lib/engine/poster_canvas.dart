import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/utils/color_utils.dart';
import '../models/design_model.dart';
import '../models/text_layer_model.dart';
import 'layer_view.dart';

/// A non-interactive render of a full [PosterDesign]. Used for template cards,
/// thumbnails, and (wrapped in a RepaintBoundary) for high-resolution export.
///
/// The editor renders the same background + overlay but positions its own
/// interactive layer widgets on top.
class PosterCanvas extends StatelessWidget {
  final PosterDesign design;

  const PosterCanvas({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: design.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fill(child: PosterBackground(design: design)),
                Positioned.fill(child: PosterOverlay(design: design)),
                for (final layer in design.layers) _positioned(layer, w, h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _positioned(PosterLayer layer, double w, double h) {
    return Positioned(
      left: layer.x * w,
      top: layer.y * h,
      width: layer.width * w,
      height: layer.height * h,
      child: Opacity(
        opacity: layer.opacity,
        child: Transform.rotate(
          angle: layer.rotationRadians,
          child: LayerView(layer: layer, canvasWidth: w),
        ),
      ),
    );
  }

}

/// The background image or solid colour for a design.
class PosterBackground extends StatelessWidget {
  final PosterDesign design;
  const PosterBackground({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    final bg = ColorUtils.fromHex(design.backgroundColorHex, fallback: Colors.black);
    if (design.backgroundLocalPath != null && design.backgroundLocalPath!.isNotEmpty) {
      return Image.file(File(design.backgroundLocalPath!),
          fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: bg));
    }
    if (design.backgroundUrl != null && design.backgroundUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: design.backgroundUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => ColoredBox(color: bg),
        errorWidget: (_, _, _) => ColoredBox(color: bg),
      );
    }
    return ColoredBox(color: bg);
  }
}

/// The readability overlay (solid tint or vertical gradient) above the image.
class PosterOverlay extends StatelessWidget {
  final PosterDesign design;
  const PosterOverlay({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    final from = ColorUtils.fromHex(design.overlayHex, fallback: Colors.transparent);
    if (design.overlayGradientToHex != null) {
      final to = ColorUtils.fromHex(design.overlayGradientToHex, fallback: Colors.transparent);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [from, to],
          ),
        ),
      );
    }
    return ColoredBox(color: from);
  }
}
