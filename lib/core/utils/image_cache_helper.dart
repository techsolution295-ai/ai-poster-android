import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches remote images to the device's local storage.
///
/// This is what lets the app respect the Pixabay "no permanent hotlinking"
/// rule: when a Pixabay background is chosen it is downloaded here and the
/// local file path is used from then on. It also speeds up repeat views of any
/// background.
class ImageCacheHelper {
  ImageCacheHelper._();

  static Directory? _dir;

  static Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/poster_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  static String _fileNameFor(String url) {
    final hash = url.hashCode.toUnsigned(32).toRadixString(16);
    final ext = url.contains('.png') ? 'png' : 'jpg';
    return 'bg_$hash.$ext';
  }

  /// Returns the local path for [url], downloading it first if not already
  /// cached. Returns null on failure (caller can fall back to the URL).
  static Future<String?> cache(String url) async {
    if (url.isEmpty) return null;
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${_fileNameFor(url)}');
      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) return null;
      await file.writeAsBytes(res.bodyBytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('ImageCacheHelper.cache failed: $e');
      return null;
    }
  }

  /// Saves raw bytes (e.g. an exported preview) to the cache and returns the path.
  static Future<String> saveBytes(List<int> bytes, String fileName) async {
    final dir = await _cacheDir();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Total size of the cache directory in bytes.
  static Future<int> cacheSize() async {
    try {
      final dir = await _cacheDir();
      var total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clearCache() async {
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _dir = null;
    } catch (e) {
      debugPrint('ImageCacheHelper.clearCache failed: $e');
    }
  }
}
