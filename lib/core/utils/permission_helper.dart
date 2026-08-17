import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around runtime permissions needed for saving/exporting posters
/// and picking a logo. Fails safe: if a check throws we assume granted and let
/// the underlying plugin surface any real error.
class PermissionHelper {
  PermissionHelper._();

  /// Permission to save an image to the gallery. On Android 13+ (API 33) the
  /// system photo picker / MediaStore generally doesn't need this, so we only
  /// request on older versions.
  static Future<bool> ensureGallerySave() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      if (Platform.isIOS) {
        final status = await Permission.photosAddOnly.request();
        return status.isGranted || status.isLimited;
      }
      // Android: try photos (13+) then storage (older).
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    } catch (e) {
      debugPrint('PermissionHelper.ensureGallerySave: $e');
      return true;
    }
  }
}
