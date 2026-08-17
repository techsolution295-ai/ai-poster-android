import 'dart:math';

import 'stock_image.dart';

/// Free AI image generation helper using Pollinations image API.
///
/// This endpoint is simple (no key required) and can be slow at times.
/// We generate multiple seeded variants for the same prompt so the results
/// screen gets a small poster set instead of a single image.
class AiPosterApiService {
  AiPosterApiService._();
  static final AiPosterApiService instance = AiPosterApiService._();

  final _rand = Random();

  Future<List<StockImage>> generatePosterImages({
    required String prompt,
    int count = 10,
    int width = 1080,
    int height = 1350,
  }) async {
    final safePrompt = prompt.trim();
    if (safePrompt.isEmpty) return const [];

    final images = <StockImage>[];
    for (var i = 0; i < count; i++) {
      final seed = _rand.nextInt(99999999);
      final fullPrompt =
          '$safePrompt, poster design, modern, high quality, typography, no watermark';
      final encoded = Uri.encodeComponent(fullPrompt);
      final url =
          'https://image.pollinations.ai/prompt/$encoded?seed=$seed&width=$width&height=$height&nologo=true';
      images.add(
        StockImage(
          url: url,
          previewUrl: url,
          sourceName: 'Pollinations AI',
          sourcePageUrl: 'https://pollinations.ai',
          photographerName: null,
          licenseNote: 'Generated via Pollinations AI (free endpoint).',
          requiresLocalCache: false,
        ),
      );
    }
    return images;
  }
}

