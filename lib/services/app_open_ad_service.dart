import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Cold-start app-open ad (AdMob policy: splash / first open only here).
///
/// - Requests only after consent + SDK ready.
/// - Fills expire after 4 hours (Google guidance).
/// - One retry with backoff; no request spam.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  static const _maxCacheAge = Duration(hours: 4);

  AppOpenAd? _appOpenAd;
  DateTime? _loadedAt;
  bool _isShowing = false;
  bool _isLoading = false;
  Completer<bool>? _loadCompleter;
  int _failCount = 0;

  bool get _blocked => AdService.instance.isPro;

  bool get hasAd => _appOpenAd != null && !_isExpired();

  bool _isExpired() {
    final loadedAt = _loadedAt;
    if (loadedAt == null || _appOpenAd == null) return true;
    return DateTime.now().difference(loadedAt) > _maxCacheAge;
  }

  void discard() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _loadedAt = null;
    _isLoading = false;
    if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
      _loadCompleter!.complete(false);
    }
    _loadCompleter = null;
  }

  /// Consent-aware load. Call after [AdService.ensureReady].
  Future<bool> loadAd({bool allowRetry = true}) async {
    if (!AdService.instance.isSupported || _blocked) {
      discard();
      return false;
    }

    if (!AdService.instance.sdkReady || !AdService.instance.canRequestAds) {
      await AdService.instance.ensureReady();
      if (!AdService.instance.sdkReady || !AdService.instance.canRequestAds) {
        return false;
      }
    }

    if (_isExpired()) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _loadedAt = null;
    }

    if (_appOpenAd != null) return true;
    if (_isLoading) return _loadCompleter?.future ?? Future.value(false);
    if (_loadCompleter != null) return _loadCompleter!.future;

    _loadCompleter = Completer<bool>();
    _isLoading = true;
    debugPrint('AppOpenAd: AdRequest');

    try {
      AppOpenAd.load(
        adUnitId: AdService.instance.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (_blocked) {
              ad.dispose();
              _finishLoad(false);
              return;
            }
            _appOpenAd = ad;
            _loadedAt = DateTime.now();
            _failCount = 0;
            debugPrint('AppOpenAd: loaded');
            _finishLoad(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('App open failed: $error');
            _failCount++;
            _finishLoad(false);
            if (allowRetry && _failCount == 1 && !_blocked) {
              Future<void>.delayed(const Duration(seconds: 3), () {
                if (_appOpenAd == null && !_isLoading) {
                  unawaited(loadAd(allowRetry: false));
                }
              });
            }
          },
        ),
      );
    } on PlatformException catch (error) {
      debugPrint('App open load error: $error');
      _finishLoad(false);
      return false;
    }

    return _loadCompleter!.future;
  }

  void _finishLoad(bool success) {
    _isLoading = false;
    final completer = _loadCompleter;
    _loadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  /// Splash show. [loadTimeout] should be up to 8s on first open.
  Future<bool> showAdIfAvailable({
    Duration loadTimeout = const Duration(seconds: 8),
  }) async {
    if (!AdService.instance.isSupported ||
        _blocked ||
        _isShowing ||
        !AdService.instance.canRequestAds) {
      return false;
    }

    if (_isExpired()) discard();

    final loaded = await loadAd().timeout(
      loadTimeout,
      onTimeout: () {
        debugPrint('AppOpenAd: timed out after ${loadTimeout.inSeconds}s');
        return hasAd;
      },
    );

    if (_blocked) {
      discard();
      return false;
    }
    if (!loaded || _appOpenAd == null || _isExpired()) {
      debugPrint('AppOpenAd: nothing to show');
      return false;
    }

    final completer = Completer<void>();
    var didShow = false;
    _isShowing = true;
    final ad = _appOpenAd!;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        _disposeAd(shown);
        _isShowing = false;
        AdService.restoreSystemBars();
        if (!completer.isCompleted) completer.complete();
        // Prefetch next open + interstitial after dismiss (policy-friendly).
        if (!_blocked) {
          unawaited(loadAd());
          unawaited(AdService.instance.prefetchInterstitial());
        }
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        debugPrint('App open failed to show: $error');
        _disposeAd(shown);
        _isShowing = false;
        AdService.restoreSystemBars();
        if (!completer.isCompleted) completer.complete();
        if (!_blocked) unawaited(loadAd());
      },
      onAdShowedFullScreenContent: (_) {
        didShow = true;
        AdService.instance.markFullscreenShown();
        debugPrint('AppOpenAd: showing');
      },
    );

    try {
      await AdService.prepareFullScreen(ad);
      await ad.show();
      await completer.future;
    } catch (error) {
      debugPrint('App open show error: $error');
      _isShowing = false;
      AdService.restoreSystemBars();
      if (_appOpenAd != null) _disposeAd(_appOpenAd!);
    } finally {
      _isShowing = false;
      AdService.restoreSystemBars();
    }
    return didShow;
  }

  void _disposeAd(AppOpenAd ad) {
    ad.dispose();
    if (identical(_appOpenAd, ad)) {
      _appOpenAd = null;
      _loadedAt = null;
    }
  }
}
