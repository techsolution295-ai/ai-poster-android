import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The kinds of editable layers the poster editor supports.
enum LayerType { text, image, shape, icon }

/// Semantic role of a layer. Used by the layout engine to auto-fill content
/// from the user's brand profile and category defaults (e.g. the layer with
/// role `title` receives the category's default title).
enum LayerRole {
  none,
  title,
  subtitle,
  details,
  price,
  logo,
  contact,
  website,
  background,
  overlay,
}

LayerType _layerTypeFromString(String? s) =>
    LayerType.values.firstWhere((e) => e.name == s, orElse: () => LayerType.text);

LayerRole _layerRoleFromString(String? s) =>
    LayerRole.values.firstWhere((e) => e.name == s, orElse: () => LayerRole.none);

/// A single editable element on the poster canvas.
///
/// All geometry is stored **normalised** (0..1) relative to the canvas so a
/// design renders identically at any export resolution (1080px, A4, etc.).
class PosterLayer {
  String id;
  LayerType type;
  LayerRole role;

  // Normalised geometry (fraction of canvas). x/y = top-left corner.
  double x;
  double y;
  double width;
  double height;

  /// Rotation in degrees (friendlier for JSON than radians).
  double rotation;
  double opacity;

  // --- Text properties -----------------------------------------------------
  String text;
  String fontFamily;

  /// Font size as a fraction of the canvas width (resolution independent).
  double fontSizeFactor;
  String colorHex;
  bool bold;
  bool italic;
  TextAlign align;
  double letterSpacing;
  bool hasShadow;

  // --- Shape properties ----------------------------------------------------
  /// One of: rect, rounded, circle, line, gradient.
  String shape;
  String fillHex;
  double cornerRadius; // fraction of canvas width
  String? gradientToHex;

  // --- Image properties ----------------------------------------------------
  /// Network URL or local file path.
  String? imageUrl;
  String? localPath;
  BoxFit imageFit;

  // --- Icon properties -----------------------------------------------------
  String? iconName;

  bool locked;

  PosterLayer({
    required this.id,
    required this.type,
    this.role = LayerRole.none,
    this.x = 0.1,
    this.y = 0.1,
    this.width = 0.8,
    this.height = 0.15,
    this.rotation = 0,
    this.opacity = 1,
    this.text = '',
    this.fontFamily = 'Poppins',
    this.fontSizeFactor = 0.07,
    this.colorHex = '#FFFFFFFF',
    this.bold = false,
    this.italic = false,
    this.align = TextAlign.center,
    this.letterSpacing = 0,
    this.hasShadow = true,
    this.shape = 'rounded',
    this.fillHex = '#66000000',
    this.cornerRadius = 0.03,
    this.gradientToHex,
    this.imageUrl,
    this.localPath,
    this.imageFit = BoxFit.cover,
    this.iconName,
    this.locked = false,
  });

  double get rotationRadians => rotation * math.pi / 180.0;

  PosterLayer copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    String? text,
    String? fontFamily,
    double? fontSizeFactor,
    String? colorHex,
    bool? bold,
    bool? italic,
    TextAlign? align,
    double? letterSpacing,
    bool? hasShadow,
    String? shape,
    String? fillHex,
    double? cornerRadius,
    String? gradientToHex,
    String? imageUrl,
    String? localPath,
    BoxFit? imageFit,
    String? iconName,
    bool? locked,
  }) {
    return PosterLayer(
      id: id,
      type: type,
      role: role,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      colorHex: colorHex ?? this.colorHex,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      align: align ?? this.align,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      hasShadow: hasShadow ?? this.hasShadow,
      shape: shape ?? this.shape,
      fillHex: fillHex ?? this.fillHex,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      gradientToHex: gradientToHex ?? this.gradientToHex,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      imageFit: imageFit ?? this.imageFit,
      iconName: iconName ?? this.iconName,
      locked: locked ?? this.locked,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'role': role.name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
        'opacity': opacity,
        'text': text,
        'fontFamily': fontFamily,
        'fontSizeFactor': fontSizeFactor,
        'colorHex': colorHex,
        'bold': bold,
        'italic': italic,
        'align': align.name,
        'letterSpacing': letterSpacing,
        'hasShadow': hasShadow,
        'shape': shape,
        'fillHex': fillHex,
        'cornerRadius': cornerRadius,
        'gradientToHex': gradientToHex,
        'imageUrl': imageUrl,
        'localPath': localPath,
        'imageFit': imageFit.name,
        'iconName': iconName,
        'locked': locked,
      };

  factory PosterLayer.fromMap(Map<String, dynamic> m) {
    return PosterLayer(
      id: m['id']?.toString() ?? UniqueKey().toString(),
      type: _layerTypeFromString(m['type']?.toString()),
      role: _layerRoleFromString(m['role']?.toString()),
      x: (m['x'] as num?)?.toDouble() ?? 0.1,
      y: (m['y'] as num?)?.toDouble() ?? 0.1,
      width: (m['width'] as num?)?.toDouble() ?? 0.8,
      height: (m['height'] as num?)?.toDouble() ?? 0.15,
      rotation: (m['rotation'] as num?)?.toDouble() ?? 0,
      opacity: (m['opacity'] as num?)?.toDouble() ?? 1,
      text: m['text']?.toString() ?? '',
      fontFamily: m['fontFamily']?.toString() ?? 'Poppins',
      fontSizeFactor: (m['fontSizeFactor'] as num?)?.toDouble() ?? 0.07,
      colorHex: m['colorHex']?.toString() ?? '#FFFFFFFF',
      bold: m['bold'] == true,
      italic: m['italic'] == true,
      align: TextAlign.values.firstWhere(
        (e) => e.name == m['align'],
        orElse: () => TextAlign.center,
      ),
      letterSpacing: (m['letterSpacing'] as num?)?.toDouble() ?? 0,
      hasShadow: m['hasShadow'] != false,
      shape: m['shape']?.toString() ?? 'rounded',
      fillHex: m['fillHex']?.toString() ?? '#66000000',
      cornerRadius: (m['cornerRadius'] as num?)?.toDouble() ?? 0.03,
      gradientToHex: m['gradientToHex']?.toString(),
      imageUrl: m['imageUrl']?.toString(),
      localPath: m['localPath']?.toString(),
      imageFit: BoxFit.values.firstWhere(
        (e) => e.name == m['imageFit'],
        orElse: () => BoxFit.cover,
      ),
      iconName: m['iconName']?.toString(),
      locked: m['locked'] == true,
    );
  }
}
