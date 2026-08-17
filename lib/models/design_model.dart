import 'text_layer_model.dart';

/// The full, serialisable description of a poster. This is what gets stored as
/// `design_json` on a template or a user design and what the editor / renderer
/// consumes.
class PosterDesign {
  String layoutId;

  /// Background image (remote or local). If null, [backgroundColorHex] is used.
  String? backgroundUrl;
  String? backgroundLocalPath;
  String backgroundColorHex;

  /// Overlay drawn on top of the background to keep text readable.
  String overlayHex; // solid or top gradient colour
  String? overlayGradientToHex; // if set, gradient overlay top->bottom
  double overlayOpacity;

  /// Canvas aspect ratio (width / height). Editor previews at this ratio and
  /// export sizes are matched against it.
  double aspectRatio;

  List<PosterLayer> layers;

  // Attribution (shown on the Credits screen).
  String? sourceName; // 'Pexels' | 'Pixabay'
  String? sourcePageUrl;
  String? photographerName;

  PosterDesign({
    required this.layoutId,
    this.backgroundUrl,
    this.backgroundLocalPath,
    this.backgroundColorHex = '#FF111827',
    this.overlayHex = '#66000000',
    this.overlayGradientToHex,
    this.overlayOpacity = 1.0,
    this.aspectRatio = 1.0,
    List<PosterLayer>? layers,
    this.sourceName,
    this.sourcePageUrl,
    this.photographerName,
  }) : layers = layers ?? [];

  PosterDesign clone() => PosterDesign.fromMap(toMap());

  Map<String, dynamic> toMap() => {
        'layoutId': layoutId,
        'backgroundUrl': backgroundUrl,
        'backgroundLocalPath': backgroundLocalPath,
        'backgroundColorHex': backgroundColorHex,
        'overlayHex': overlayHex,
        'overlayGradientToHex': overlayGradientToHex,
        'overlayOpacity': overlayOpacity,
        'aspectRatio': aspectRatio,
        'layers': layers.map((e) => e.toMap()).toList(),
        'sourceName': sourceName,
        'sourcePageUrl': sourcePageUrl,
        'photographerName': photographerName,
      };

  factory PosterDesign.fromMap(Map<String, dynamic> m) {
    return PosterDesign(
      layoutId: m['layoutId']?.toString() ?? 'layout_01',
      backgroundUrl: m['backgroundUrl']?.toString(),
      backgroundLocalPath: m['backgroundLocalPath']?.toString(),
      backgroundColorHex: m['backgroundColorHex']?.toString() ?? '#FF111827',
      overlayHex: m['overlayHex']?.toString() ?? '#66000000',
      overlayGradientToHex: m['overlayGradientToHex']?.toString(),
      overlayOpacity: (m['overlayOpacity'] as num?)?.toDouble() ?? 1.0,
      aspectRatio: (m['aspectRatio'] as num?)?.toDouble() ?? 1.0,
      layers: (m['layers'] as List?)
              ?.map((e) => PosterLayer.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      sourceName: m['sourceName']?.toString(),
      sourcePageUrl: m['sourcePageUrl']?.toString(),
      photographerName: m['photographerName']?.toString(),
    );
  }
}

/// A saved design record stored in the local history (Hive). Wraps the poster
/// [PosterDesign] JSON with metadata for the History screen.
class SavedDesign {
  final String id;
  final String categoryId;
  final String categoryName;
  final String title;
  final Map<String, dynamic> designJson;
  final String previewPath; // local preview image
  final String backgroundPath; // local cached background (if any)
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedDesign({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    this.title = '',
    required this.designJson,
    this.previewPath = '',
    this.backgroundPath = '',
    required this.createdAt,
    required this.updatedAt,
  });

  PosterDesign get design => PosterDesign.fromMap(designJson);

  SavedDesign copyWith({
    Map<String, dynamic>? designJson,
    String? previewPath,
    String? backgroundPath,
    String? title,
    DateTime? updatedAt,
  }) {
    return SavedDesign(
      id: id,
      categoryId: categoryId,
      categoryName: categoryName,
      title: title ?? this.title,
      designJson: designJson ?? this.designJson,
      previewPath: previewPath ?? this.previewPath,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'category_name': categoryName,
        'title': title,
        'design_json': designJson,
        'preview_path': previewPath,
        'background_path': backgroundPath,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory SavedDesign.fromMap(Map<String, dynamic> m) {
    return SavedDesign(
      id: m['id']?.toString() ?? '',
      categoryId: m['category_id']?.toString() ?? '',
      categoryName: m['category_name']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      designJson: Map<String, dynamic>.from(m['design_json'] as Map? ?? {}),
      previewPath: m['preview_path']?.toString() ?? '',
      backgroundPath: m['background_path']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (m['created_at'] as num?)?.toInt() ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (m['updated_at'] as num?)?.toInt() ?? 0),
    );
  }
}
