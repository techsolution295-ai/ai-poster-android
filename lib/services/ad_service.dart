import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Banner and interstitial ads.
///
/// Debug builds use Google's test units. Release builds use the live Poster
/// Maker units, so a store build never serves a test ad.
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

  /// Ads are wired for the Android release. Other platforms skip them.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String get bannerAdUnitId => kDebugMode ? _testBannerId : _productionBannerId;

  String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialId : _productionInterstitialId;

  String get appOpenAdUnitId =>
      kDebugMode ? _testAppOpenId : _productionAppOpenId;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;
  bool _started = false;
  Future<void>? _sdkInit;

  /// Starts the Mobile Ads SDK. Safe to call more than once.
  Future<void> ensureInitialized() {
    if (!isSupported) return Future<void>.value();
    return _sdkInit ??= _initSdk();
  }

  Future<void> _initSdk() async {
    try {
      await MobileAds.instance.initialize();
    } catch (error) {
      if (kDebugMode) debugPrint('MobileAds init error: $error');
    }
    initialize();
  }

  void initialize() {
    if (_started || !isSupported) return;
    _started = true;
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (!isSupported) return;
    if (_interstitialAd != null || _isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          if (kDebugMode) {
            debugPrint('Interstitial failed to load: $error');
          }
        },
      ),
    ).catchError((Object error) {
      _isLoadingInterstitial = false;
      if (kDebugMode) debugPrint('Interstitial load error: $error');
    });
  }

  /// Home template open. Shows a loaded interstitial, then continues.
  /// Waits briefly for a load so the first tap is not skipped.
  Future<void> showSelectInterstitialThen(
    Future<void> Function() action,
  ) async {
    if (!isSupported || _isShowingInterstitial) {
      await action();
      return;
    }

    if (_interstitialAd == null) {
      _loadInterstitial();
      final deadline = DateTime.now().add(const Duration(seconds: 4));
      while (_interstitialAd == null && DateTime.now().isBefore(deadline)) {
        if (!_isLoadingInterstitial) _loadInterstitial();
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      await action();
      _loadInterstitial();
      return;
    }

    final completer = Completer<void>();
    var released = false;
    void release(InterstitialAd shown) {
      if (released) return;
      released = true;
      shown.dispose();
      _interstitialAd = null;
      _isShowingInterstitial = false;
      if (!completer.isCompleted) completer.complete();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: release,
      onAdFailedToShowFullScreenContent: (shown, error) => release(shown),
    );

    _interstitialAd = null;
    _isShowingInterstitial = true;
    try {
      await ad.show().timeout(const Duration(seconds: 8));
      await completer.future.timeout(const Duration(seconds: 45));
    } catch (error) {
      if (kDebugMode) debugPrint('Interstitial show error: $error');
      release(ad);
    }
    try {
      await action();
    } finally {
      if (!_isLoadingInterstitial) _loadInterstitial();
    }
  }
}
