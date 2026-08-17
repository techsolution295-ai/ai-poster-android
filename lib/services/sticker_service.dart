import 'dart:convert';

import 'package:http/http.dart' as http;

/// Sticker categories and CDN URLs (same source as the reference Poster Maker app).
class StickerCategory {
  final String id;
  final String title;
  final int count;

  const StickerCategory({
    required this.id,
    required this.title,
    required this.count,
  });

  factory StickerCategory.fromJson(Map<String, dynamic> json) {
    final rawCount = json['IconCount'] ?? json['iconCount'] ?? 0;
    final count = rawCount is int ? rawCount : int.tryParse('$rawCount') ?? 0;
    return StickerCategory(
      id: json['iconCatName'] as String? ?? '',
      title: json['iconCatTitle'] as String? ?? '',
      count: count,
    );
  }
}

class StickerService {
  StickerService._();
  static final StickerService instance = StickerService._();

  static const String _base = 'https://d3rxtco8eq395y.cloudfront.net';
  static const String _categoriesUrl = '$_base/Json/Categories.json';

  List<StickerCategory>? _cache;

  String thumbnailUrl(String categoryId, int oneBasedIndex) {
    final segment = categoryId.trim().replaceAll(' ', '+');
    return '$_base/Stickers/$segment/Thumbnails/$oneBasedIndex.png';
  }

  List<String> thumbnailsFor(StickerCategory category) {
    if (category.count <= 0) return const [];
    return List<String>.generate(
      category.count,
      (i) => thumbnailUrl(category.id, i + 1),
    );
  }

  Future<List<StickerCategory>> loadCategories() async {
    if (_cache != null) return _cache!;
    final res = await http.get(Uri.parse(_categoriesUrl));
    if (res.statusCode != 200) {
      throw StateError('Could not load stickers (${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (json['stickers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StickerCategory.fromJson)
        .where((c) => c.id.isNotEmpty && c.count > 0)
        .toList();
    _cache = list;
    return list;
  }
}
