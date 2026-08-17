/// A dynamically generated template: one background image paired with one
/// local layout + category default texts. Produced by
/// `TemplateGeneratorService` — never manually authored.
class TemplateModel {
  final String id;
  final String categoryId;
  final String title;
  final String layoutId;

  /// Remote background URL (used only to build the design; Pixabay images are
  /// cached locally when the template is opened).
  final String backgroundUrl;

  // Attribution metadata (shown on the Image Credits screen).
  final String sourceName; // 'Pexels' | 'Pixabay' | 'Lorem Picsum (demo)'
  final String sourcePageUrl;
  final String? photographerName;

  final Map<String, String> defaultTexts;
  final String defaultFont;

  const TemplateModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.layoutId,
    this.backgroundUrl = '',
    this.sourceName = '',
    this.sourcePageUrl = '',
    this.photographerName,
    this.defaultTexts = const {},
    this.defaultFont = 'Poppins',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'title': title,
        'layout_id': layoutId,
        'background_url': backgroundUrl,
        'source_name': sourceName,
        'source_page_url': sourcePageUrl,
        'photographer_name': photographerName,
        'default_texts': defaultTexts,
        'default_font': defaultFont,
      };

  factory TemplateModel.fromMap(Map<String, dynamic> m) {
    return TemplateModel(
      id: m['id']?.toString() ?? '',
      categoryId: m['category_id']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      layoutId: m['layout_id']?.toString() ?? 'layout_01',
      backgroundUrl: m['background_url']?.toString() ?? '',
      sourceName: m['source_name']?.toString() ?? '',
      sourcePageUrl: m['source_page_url']?.toString() ?? '',
      photographerName: m['photographer_name']?.toString(),
      defaultTexts: Map<String, String>.from(
          (m['default_texts'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString()))),
      defaultFont: m['default_font']?.toString() ?? 'Poppins',
    );
  }
}
