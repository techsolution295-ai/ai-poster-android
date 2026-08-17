/// A single stock image result plus the attribution metadata we keep for the
/// Image Credits screen.
class StockImage {
  final String url; // full-size image URL
  final String previewUrl; // smaller preview/thumbnail URL
  final String sourceName; // 'Pexels' | 'Pixabay' | 'Lorem Picsum (demo)'
  final String sourcePageUrl;
  final String? photographerName;
  final String licenseNote;

  /// Pixabay requires local caching (no permanent hotlinking). Pexels may be
  /// displayed directly with attribution.
  final bool requiresLocalCache;

  const StockImage({
    required this.url,
    required this.previewUrl,
    required this.sourceName,
    required this.sourcePageUrl,
    this.photographerName,
    this.licenseNote = '',
    this.requiresLocalCache = false,
  });
}
