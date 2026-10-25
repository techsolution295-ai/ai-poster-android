import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Interstitial + banner ads with AdMob policy-safe request timing.
///
/// - Consent (UMP) runs before any ad request.
/// - Interstitials only at natural breaks (template open).
/// - Cooldown after app-open and between interstitials.
/// - Cached ads expire; failed loads retry once with backoff (no spam).
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';

  static const _productionBannerId = 'ca-app-pub-8476267163759140/8742029361';
  static const _productionInterstitialId =
      'ca-app-pub-8476267163759140/5868454012';
  static const _productionAppOpenId = 'ca-app-pub-8476267163759140/1732188875';

  /// Google: do not show another fullscreen ad too soon after app-open.
  static const _afterAppOpenCooldown = Duration(seconds: 45);

  /// Soft frequency cap between interstitials (natural breaks still apply).
  static const _interstitialCooldown = Duration(seconds: 60);

  /// Discard stale interstitial fills.
  static const _interstitialMaxAge = Duration(hours: 1);

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String get bannerAdUnitId => kDebugMode ? _testBannerId : _productionBannerId;

  String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialId : _productionInterstitialId;

  String get appOpenAdUnitId =>
      kDebugMode ? _testAppOpenId : _productionAppOpenId;

  bool get isPro => _isPro();

  bool get hasInterstitial =>
      _interstitialAd != null && !_isInterstitialExpired();

  bool get canRequestAds => _canRequestAds;

  bool sdkReady = false;

  bool Function() _isPro = () => false;

  InterstitialAd? _interstitialAd;
  DateTime? _interstitialLoadedAt;
  DateTime? _lastFullscreenShownAt;
  DateTime? _lastInterstitialShownAt;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;
  bool _canRequestAds = true;
  Completer<bool>? _interstitialLoadCompleter;
  Future<void>? _readyFuture;
  int _interstitialFailCount = 0;

  void bind({required bool Function() isPro}) {
    _isPro = isPro;
  }

  /// Call after any fullscreen ad is shown (app-open or interstitial).
  void markFullscreenShown() {
    _lastFullscreenShownAt = DateTime.now();
  }

  /// UMP consent → Mobile Ads init → first interstitial prefetch.
  Future<void> ensureReady() {
    if (!isSupported || _isPro()) return Future<void>.value();
    return _readyFuture ??= _doEnsureReady();
  }

  Future<void> _doEnsureReady() async {
    try {
      await _gatherConsent();
      if (!_canRequestAds) {
        debugPrint('AdService: cannot request ads (consent)');
        return;
      }

      await MobileAds.instance
          .initialize()
          .timeout(const Duration(seconds: 8));
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg,
        ),
      );
      sdkReady = true;
      debugPrint(
        kDebugMode
            ? 'AdService: ready (test units)'
            : 'AdService: ready (live units)',
      );
      unawaited(prefetchInterstitial());
    } catch (error) {
      debugPrint('Ads init failed: $error');
      _readyFuture = null;
    }
  }

  Future<void> _gatherConsent() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        } catch (error) {
          debugPrint('Consent form error: $error');
        }
        try {
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
        } catch (_) {
          _canRequestAds = true;
        }
        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
        debugPrint('Consent info update failed: ${error.message}');
        _canRequestAds = true;
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        debugPrint('Consent timed out; continuing');
        _canRequestAds = true;
      },
    );
  }

  void syncWithPro(bool isPro) {
    if (isPro) {
      _disposeInterstitial();
      return;
    }
    if (sdkReady && _canRequestAds) unawaited(prefetchInterstitial());
  }

  /// Prefetch one interstitial. Waits up to [timeout] for the fill.
  Future<bool> prefetchInterstitial({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!isSupported || _isPro() || !_canRequestAds) return false;
    if (!sdkReady) {
      await ensureReady();
      if (!sdkReady || !_canRequestAds) return false;
    }
    if (hasInterstitial) return true;

    _requestInterstitial();
    final completer = _interstitialLoadCompleter;
    if (completer == null) return hasInterstitial;

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => hasInterstitial,
      );
    } catch (_) {
      return hasInterstitial;
    }
  }

  void _requestInterstitial() {
    if (!sdkReady || !isSupported || _isPro() || !_canRequestAds) return;
    if (hasInterstitial || _isLoadingInterstitial) return;

    _isLoadingInterstitial = true;
    _interstitialLoadCompleter = Completer<bool>();
    debugPrint('AdService: AdRequest interstitial');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_isPro()) {
            ad.dispose();
            _finishInterstitialLoad(false);
            return;
          }
          _interstitialAd = ad;
          _interstitialLoadedAt = DateTime.now();
          _interstitialFailCount = 0;
          debugPrint('AdService: interstitial loaded');
          _finishInterstitialLoad(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: $error');
          _interstitialFailCount++;
          _finishInterstitialLoad(false);
          // One delayed retry only — avoids request spam (policy).
          if (_interstitialFailCount == 1 && !_isPro()) {
            Future<void>.delayed(const Duration(seconds: 5), () {
              if (!hasInterstitial && !_isLoadingInterstitial) {
                _requestInterstitial();
              }
            });
          }
        },
      ),
    );
  }

  void _finishInterstitialLoad(bool success) {
    _isLoadingInterstitial = false;
    final completer = _interstitialLoadCompleter;
    _interstitialLoadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  bool _isInterstitialExpired() {
    final loadedAt = _interstitialLoadedAt;
    if (loadedAt == null) return true;
    return DateTime.now().difference(loadedAt) > _interstitialMaxAge;
  }

  bool _cooldownBlocksShow() {
    final now = DateTime.now();
    final afterOpen = _lastFullscreenShownAt;
    if (afterOpen != null &&
        now.difference(afterOpen) < _afterAppOpenCooldown) {
      debugPrint('AdService: skip interstitial (after app-open cooldown)');
      return true;
    }
    final last = _lastInterstitialShownAt;
    if (last != null && now.difference(last) < _interstitialCooldown) {
      debugPrint('AdService: skip interstitial (frequency cooldown)');
      return true;
    }
    return false;
  }

  void _disposeInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _interstitialLoadedAt = null;
    _isLoadingInterstitial = false;
  }

  /// Natural break: home / history template open.
  Future<void> showSelectInterstitialThen(
    Future<void> Function() action,
  ) async {
    if (!isSupported || _isPro() || _isShowingInterstitial) {
      await action();
      return;
    }

    if (!sdkReady || !_canRequestAds) {
      await ensureReady().timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    }

    if (_cooldownBlocksShow()) {
      await action();
      unawaited(prefetchInterstitial());
      return;
    }

    if (_isInterstitialExpired()) {
      _disposeInterstitial();
    }

    // Prefer a warm ad. Short wait only — never block the UX for long.
    if (!hasInterstitial) {
      await prefetchInterstitial(timeout: const Duration(seconds: 2));
    }

    final ad = _interstitialAd;
    if (ad == null || _isPro() || _cooldownBlocksShow()) {
      ad?.dispose();
      _interstitialAd = null;
      await action();
      unawaited(prefetchInterstitial());
      return;
    }

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        _interstitialAd = null;
        _interstitialLoadedAt = null;
        _isShowingInterstitial = false;
        restoreSystemBars();
        if (!completer.isCompleted) completer.complete();
        unawaited(prefetchInterstitial());
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        debugPrint('Interstitial failed to show: $error');
        shown.dispose();
        _interstitialAd = null;
        _interstitialLoadedAt = null;
        _isShowingInterstitial = false;
        restoreSystemBars();
        if (!completer.isCompleted) completer.complete();
        unawaited(prefetchInterstitial());
      },
      onAdShowedFullScreenContent: (_) {
        _lastInterstitialShownAt = DateTime.now();
        markFullscreenShown();
      },
    );

    _interstitialAd = null;
    _interstitialLoadedAt = null;
    _isShowingInterstitial = true;
    try {
      await prepareFullScreen(ad);
      await ad.show();
      await completer.future;
    } catch (error) {
      debugPrint('Interstitial show error: $error');
      ad.dispose();
      _isShowingInterstitial = false;
      restoreSystemBars();
      if (!completer.isCompleted) completer.complete();
    } finally {
      _isShowingInterstitial = false;
      restoreSystemBars();
    }

    try {
      await action();
    } finally {
      if (!_isPro()) unawaited(prefetchInterstitial());
    }
  }

  static Future<void> prepareFullScreen(AdWithoutView ad) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    try {
      await ad.setImmersiveMode(true);
    } catch (error) {
      if (kDebugMode) debugPrint('Immersive ad mode failed: $error');
    }
  }

  static void restoreSystemBars() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      ),
    );
  }
}
