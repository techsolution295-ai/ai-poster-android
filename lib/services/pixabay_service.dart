import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_keys.dart';
import 'stock_image.dart';

/// Fetches free stock photos from the Pixabay API.
///
/// IMPORTANT (Pixabay terms): we must not permanently hotlink Pixabay CDN URLs.
/// Every result is flagged with [StockImage.requiresLocalCache] = true; when a
/// user opens/selects such an image the app downloads it to the device
/// (see `ImageCacheHelper`) and uses the local file path afterwards.
class PixabayService {
  PixabayService._();
  static final PixabayService instance = PixabayService._();

  final _client = http.Client();

  Future<List<StockImage>> search(String query, {int perPage = 20, int page = 1}) async {
    if (!ApiKeys.hasPixabay) return [];
    // Pixabay requires per_page >= 3.
    final safePerPage = perPage < 3 ? 3 : perPage;
    final uri = Uri.parse('https://pixabay.com/api/'
        '?key=${ApiKeys.pixabay}&q=${Uri.encodeQueryComponent(query)}'
        '&image_type=photo&safesearch=true&per_page=$safePerPage&page=$page');
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        debugPrint('Pixabay ${res.statusCode}: ${res.body}');
        return [];
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final hits = (data['hits'] as List?) ?? [];
      return hits
          .map((h) {
            final m = h as Map<String, dynamic>;
            return StockImage(
              url: m['largeImageURL']?.toString() ?? m['webformatURL']?.toString() ?? '',
              previewUrl: m['webformatURL']?.toString() ?? m['previewURL']?.toString() ?? '',
              sourceName: 'Pixabay',
              sourcePageUrl: m['pageURL']?.toString() ?? 'https://pixabay.com',
              photographerName: m['user']?.toString(),
              licenseNote: 'Free under the Pixabay Content License. '
                  'Cached locally on device (no hotlinking).',
              requiresLocalCache: true,
            );
          })
          .where((e) => e.url.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Pixabay request failed: $e');
      return [];
    }
  }
}
