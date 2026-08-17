import '../../services/export_service.dart';

/// Small helpers for export naming and quality mapping. The heavy lifting
/// (capturing the RepaintBoundary, encoding, saving, sharing) lives in
/// [ExportService].
class ExportHelper {
  ExportHelper._();

  /// Export quality presets that map to a rough max width used for capture.
  static int widthForQuality(String quality, int requestedWidth) {
    switch (quality) {
      case 'low':
        return requestedWidth.clamp(1, 720);
      case 'medium':
        return requestedWidth.clamp(1, 1080);
      case 'high':
      default:
        return requestedWidth; // full requested resolution
    }
  }

  static String fileName({required String prefix, required ExportFormat format}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = format == ExportFormat.png ? 'png' : 'jpg';
    return '${prefix}_$ts.$ext';
  }
}
