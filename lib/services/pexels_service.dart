import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_keys.dart';
import 'stock_image.dart';

/// Fetches free stock photos from the Pexels API.
///
/// Attribution (photographer + source page) is preserved on every [StockImage]
/// and surfaced on the Image Credits screen, as required by the Pexels license.
class PexelsService {
  PexelsService._();
  static final PexelsService instance = PexelsService._();

  final _client = http.Client();

  Future<List<StockImage>> search(String query, {int perPage = 20, int page = 1}) async {
    if (!ApiKeys.hasPexels) return [];
    final uri = Uri.parse('https://api.pexels.com/v1/search'
        '?query=${Uri.encodeQueryComponent(query)}&per_page=$perPage&page=$page');
    try {
      final res = await _client
          .get(uri, headers: {'Authorization': ApiKeys.pexels})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        debugPrint('Pexels ${res.statusCode}: ${res.body}');
        return [];
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final photos = (data['photos'] as List?) ?? [];
      return photos
          .map((p) {
            final m = p as Map<String, dynamic>;
            final src = m['src'] as Map<String, dynamic>? ?? {};
            return StockImage(
              url: src['large2x']?.toString() ?? src['large']?.toString() ?? '',
              previewUrl: src['medium']?.toString() ?? src['small']?.toString() ?? '',
              sourceName: 'Pexels',
              sourcePageUrl: m['url']?.toString() ?? 'https://www.pexels.com',
              photographerName: m['photographer']?.toString(),
              licenseNote: 'Free to use under the Pexels License.',
              requiresLocalCache: false,
            );
          })
          .where((e) => e.url.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Pexels request failed: $e');
      return [];
    }
  }
}
