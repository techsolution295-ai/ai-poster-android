import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/utils/color_utils.dart';
import '../core/utils/font_resolver.dart';
import '../core/utils/icon_resolver.dart';
import '../models/text_layer_model.dart';

/// Renders the *content* of a single [PosterLayer] to fill its parent box.
///
/// Positioning, rotation and gesture handling are the caller's responsibility
/// (see `PosterCanvas` and the editor). Keeping content rendering here means
/// previews, thumbnails, the editor and the exported image all look identical.
class LayerView extends StatelessWidget {
  final PosterLayer layer;

  /// Width of the whole canvas in logical pixels. Used to convert normalised
  /// sizes (font size factor, corner radius) into concrete pixels.
  final double canvasWidth;

  const LayerView({super.key, required this.layer, required this.canvasWidth});

  @override
  Widget build(BuildContext context) {
    switch (layer.type) {
      case LayerType.text:
        return _buildText();
      case LayerType.image:
        return _buildImage();
      case LayerType.icon:
        return _buildIcon();
      case LayerType.shape:
        return _buildShape();
    }
  }

  Widget _buildText() {
    final fontSize = (layer.fontSizeFactor * canvasWidth).clamp(4.0, 4000.0);
    final color = ColorUtils.fromHex(layer.colorHex, fallback: Colors.white);
    final style = FontResolver.style(
      layer.fontFamily,
      base: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: layer.bold ? FontWeight.w800 : FontWeight.w500,
        fontStyle: layer.italic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: layer.letterSpacing,
        height: 1.1,
        shadows: layer.hasShadow
            ? const [Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(0, 2))]
            : null,
      ),
    );

    // The text wraps within the layer's width, then the whole block is scaled
    // down (never up) so it always fits inside the layer box — no clipping or
    // half-cut text, matching how it will look when exported.
    final boxWidth = (layer.width * canvasWidth).clamp(1.0, 100000.0);
    final align = _alignmentFor(layer.align);
    return SizedBox.expand(
      child: Align(
        alignment: align,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align,
          child: SizedBox(
            width: boxWidth,
            child: Text(
              layer.text,
              textAlign: layer.align,
              style: style,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    Widget image;
    if (layer.localPath != null && layer.localPath!.isNotEmpty) {
      image = Image.file(File(layer.localPath!), fit: layer.imageFit);
    } else if (layer.imageUrl != null && layer.imageUrl!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: layer.imageUrl!,
        fit: layer.imageFit,
        placeholder: (_, _) => const ColoredBox(color: Colors.black12),
        errorWidget: (_, _, _) =>
            const Icon(Icons.broken_image, color: Colors.white54),
      );
    } else {
      image = const ColoredBox(color: Colors.black12);
    }
    return SizedBox.expand(child: image);
  }

  Widget _buildIcon() {
    return FittedBox(
      fit: BoxFit.contain,
      child: Icon(
        IconResolver.resolve(layer.iconName),
        color: ColorUtils.fromHex(layer.colorHex, fallback: Colors.white),
      ),
    );
  }

  Widget _buildShape() {
    final fill = ColorUtils.fromHex(layer.fillHex, fallback: Colors.black54);
    final radius = layer.cornerRadius * canvasWidth;

    switch (layer.shape) {
      case 'circle':
        return DecoratedBox(
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        );
      case 'border':
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: fill, width: (canvasWidth * 0.008).clamp(1.0, 40.0)),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      case 'line':
        return ColoredBox(color: fill);
      case 'gradient':
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                fill,
                ColorUtils.fromHex(layer.gradientToHex, fallback: Colors.transparent),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      case 'rect':
        return ColoredBox(color: fill);
      case 'rounded':
      default:
        return DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    }
  }

  Alignment _alignmentFor(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}
