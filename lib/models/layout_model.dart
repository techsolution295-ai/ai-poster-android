/// Maps to the `layouts` Firestore collection and to the bundled
/// `assets/layouts/layout_XX.json` files.
///
/// [jsonConfig] describes the arrangement of layers for a layout style. The
/// layout engine merges this with a chosen background + category defaults to
/// produce a [PosterDesign].
class LayoutModel {
  final String id;
  final String name;
  final Map<String, dynamic> jsonConfig;
  final String previewUrl;
  final bool isActive;

  const LayoutModel({
    required this.id,
    required this.name,
    required this.jsonConfig,
    this.previewUrl = '',
    this.isActive = true,
  });

  factory LayoutModel.fromMap(String id, Map<String, dynamic> m) {
    return LayoutModel(
      id: id,
      name: m['name']?.toString() ?? id,
      jsonConfig: Map<String, dynamic>.from(m['json_config'] as Map? ?? m),
      previewUrl: m['preview_url']?.toString() ?? '',
      isActive: m['is_active'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'json_config': jsonConfig,
        'preview_url': previewUrl,
        'is_active': isActive,
      };
}
