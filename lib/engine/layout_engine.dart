import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/brand_profile_model.dart';
import '../models/design_model.dart';
import '../models/text_layer_model.dart';

/// Turns a layout JSON definition into a fully-populated, editable
/// [PosterDesign].
///
/// This is the heart of the "auto template generator": a layout describes
/// *where* things go, and the engine fills in *what* goes there using category
/// defaults and (optionally) the user's brand profile.
class LayoutEngine {
  LayoutEngine._();

  static const _uuid = Uuid();

  /// Content that fills the semantic roles in a layout.
  /// Keys correspond to [LayerRole] names: title, subtitle, details, price, contact.
  static PosterDesign buildDesign({
    required Map<String, dynamic> layoutConfig,
    String? backgroundUrl,
    String? backgroundLocalPath,
    double aspectRatio = 1.0,
    Map<String, String> texts = const {},
    BrandProfileModel? brand,
    String? fontFamily,
    String? sourceName,
    String? sourcePageUrl,
    String? photographerName,
  }) {
    final overlay = layoutConfig['overlay'] as Map<String, dynamic>? ?? const {};
    final design = PosterDesign(
      layoutId: layoutConfig['id']?.toString() ?? 'layout_01',
      backgroundUrl: backgroundUrl,
      backgroundLocalPath: backgroundLocalPath,
      aspectRatio: aspectRatio,
      overlayHex: overlay['fromHex']?.toString() ??
          overlay['colorHex']?.toString() ??
          '#66000000',
      overlayGradientToHex:
          overlay['type'] == 'gradient' ? overlay['toHex']?.toString() : null,
      sourceName: sourceName,
      sourcePageUrl: sourcePageUrl,
      photographerName: photographerName,
    );

    final specs = (layoutConfig['layers'] as List?) ?? const [];
    for (final raw in specs) {
      final spec = Map<String, dynamic>.from(raw as Map);
      final layer = _layerFromSpec(spec, texts: texts, brand: brand, fontFamily: fontFamily);
      if (layer != null) design.layers.add(layer);
    }
    return design;
  }

  static PosterLayer? _layerFromSpec(
    Map<String, dynamic> spec, {
    required Map<String, String> texts,
    BrandProfileModel? brand,
    String? fontFamily,
  }) {
    final type = _type(spec['type']?.toString());
    final role = _role(spec['role']?.toString());

    // Resolve content for the layer's role.
    String content = '';
    switch (role) {
      case LayerRole.title:
        content = texts['title'] ?? '';
        break;
      case LayerRole.subtitle:
        content = texts['subtitle'] ?? '';
        break;
      case LayerRole.details:
        content = texts['details'] ?? '';
        break;
      case LayerRole.price:
        content = texts['price'] ?? '';
        break;
      case LayerRole.contact:
        content = _contactText(brand, texts['contact']);
        break;
      case LayerRole.website:
        content = brand?.website ?? '';
        break;
      default:
        content = texts[role.name] ?? '';
    }

    // Logo image layers get the brand logo (if any).
    String? imageUrl;
    String? localPath;
    if (type == LayerType.image && role == LayerRole.logo) {
      final logo = brand?.logo;
      if (logo != null) {
        if (logo.startsWith('http')) {
          imageUrl = logo;
        } else {
          localPath = logo;
        }
      } else {
        // No logo yet -> skip empty logo placeholder so it doesn't clutter.
        // Still keep it for text roles though.
        return null;
      }
    }

    // Skip text layers whose resolved content is empty AND has no icon/shape.
    if (type == LayerType.text && content.isEmpty) {
      return null;
    }

    // Skip decorative backing shapes for a text role that has no content
    // (e.g. an empty price badge), but always keep pure overlay/background art.
    if (type == LayerType.shape &&
        content.isEmpty &&
        (role == LayerRole.price ||
            role == LayerRole.details ||
            role == LayerRole.contact)) {
      return null;
    }

    return PosterLayer(
      id: _uuid.v4(),
      type: type,
      role: role,
      x: (spec['x'] as num?)?.toDouble() ?? 0.1,
      y: (spec['y'] as num?)?.toDouble() ?? 0.1,
      width: (spec['width'] as num?)?.toDouble() ?? 0.8,
      height: (spec['height'] as num?)?.toDouble() ?? 0.15,
      rotation: (spec['rotation'] as num?)?.toDouble() ?? 0,
      opacity: (spec['opacity'] as num?)?.toDouble() ?? 1,
      text: content,
      fontFamily: fontFamily ?? spec['fontFamily']?.toString() ?? 'Poppins',
      fontSizeFactor: (spec['fontSizeFactor'] as num?)?.toDouble() ?? 0.06,
      colorHex: spec['colorHex']?.toString() ?? '#FFFFFFFF',
      bold: spec['bold'] == true,
      italic: spec['italic'] == true,
      align: _align(spec['align']?.toString()),
      letterSpacing: (spec['letterSpacing'] as num?)?.toDouble() ?? 0,
      shape: spec['shape']?.toString() ?? 'rounded',
      fillHex: spec['fillHex']?.toString() ?? '#66000000',
      cornerRadius: (spec['cornerRadius'] as num?)?.toDouble() ?? 0.03,
      imageUrl: imageUrl,
      localPath: localPath,
      iconName: spec['iconName']?.toString(),
    );
  }

  static String _contactText(BrandProfileModel? brand, String? fallback) {
    if (brand == null || brand.isEmpty) return fallback ?? '';
    final parts = <String>[];
    if (brand.phone.isNotEmpty) parts.add(brand.phone);
    if (brand.website.isNotEmpty) parts.add(brand.website);
    if (parts.isEmpty && brand.companyName.isNotEmpty) return brand.companyName;
    return parts.join('  •  ');
  }

  static LayerType _type(String? s) =>
      LayerType.values.firstWhere((e) => e.name == s, orElse: () => LayerType.text);

  static LayerRole _role(String? s) =>
      LayerRole.values.firstWhere((e) => e.name == s, orElse: () => LayerRole.none);

  static TextAlign _align(String? s) =>
      TextAlign.values.firstWhere((e) => e.name == s, orElse: () => TextAlign.center);
}
