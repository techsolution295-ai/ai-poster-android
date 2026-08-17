/// PLACEHOLDER — there is NO premium / payment system in this MVP.
///
/// Everything in the app is free. This file exists purely so a future release
/// can introduce in-app purchases / a premium tier without reworking call
/// sites. For now [isPremium] always returns true (all features unlocked).
class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  /// MVP: every feature is unlocked for everyone.
  bool get isPremium => true;

  /// No watermark, no export limits, no locked templates in the MVP.
  bool get watermarkEnabled => false;

  Future<void> restorePurchases() async {/* no-op in MVP */}
  Future<bool> purchasePremium() async => true; // no-op in MVP
}
