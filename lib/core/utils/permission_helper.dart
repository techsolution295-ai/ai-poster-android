import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around runtime permissions needed for saving exported posters.
/// Fails safe: if a check throws we assume granted and let the underlying
/// plugin surface any real error.
class PermissionHelper {
  PermissionHelper._();

  /// Permission to save an image to the gallery.
  ///
  /// Android never requests READ_MEDIA_IMAGES or READ_MEDIA_VIDEO. Choosing a
  /// photo uses the system photo picker, and saving uses MediaStore. Gal only
  /// asks for write storage on Android 9 and below.
  static Future<bool> ensureGallerySave() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      if (Platform.isIOS) {
        final status = await Permission.photosAddOnly.request();
        return status.isGranted || status.isLimited;
      }
      if (await Gal.hasAccess()) return true;
      await Gal.requestAccess();
      return Gal.hasAccess();
    } catch (e) {
      debugPrint('PermissionHelper.ensureGallerySave: $e');
      return true;
    }
  }
}
