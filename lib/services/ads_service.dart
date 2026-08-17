import 'package:flutter/foundation.dart';

/// PLACEHOLDER — ads are intentionally NOT implemented in this MVP.
///
/// This file exists so a future version can wire up AdMob (banner /
/// interstitial / rewarded) without restructuring the app. All methods are
/// currently no-ops. Do not add real ad SDKs here for the MVP.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool get isEnabled => false;

  Future<void> init() async {
    debugPrint('AdsService: disabled (MVP has no ads).');
  }

  Future<void> showInterstitial() async {/* no-op in MVP */}
  Future<bool> showRewarded() async => false; // no-op in MVP
}
