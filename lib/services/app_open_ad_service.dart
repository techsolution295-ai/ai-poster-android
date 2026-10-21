import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Splash app-open ad. Load is capped so startup never waits forever.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _isShowing = false;
  bool _isLoading = false;
  Completer<bool>? _loadCompleter;

  void discard() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoading = false;
    if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
      _loadCompleter!.complete(false);
    }
    _loadCompleter = null;
  }

  Future<bool> loadAd() {
    if (!AdService.instance.isSupported) return Future.value(false);
    if (_appOpenAd != null) return Future.value(true);
    if (_isLoading) return _loadCompleter?.future ?? Future.value(false);

    _loadCompleter = Completer<bool>();
    _isLoading = true;
    unawaited(_loadAfterSdk());
    return _loadCompleter!.future;
  }

  Future<void> _loadAfterSdk() async {
    try {
      await AdService.instance.ensureInitialized();
      if (_appOpenAd != null || _loadCompleter == null) return;
      AppOpenAd.load(
        adUnitId: AdService.instance.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _finishLoad(true);
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) debugPrint('App open ad failed to load: $error');
            _finishLoad(false);
          },
        ),
      ).catchError((Object error) {
        if (kDebugMode) debugPrint('App open ad load error: $error');
        _finishLoad(false);
      });
    } on PlatformException catch (error) {
      if (kDebugMode) debugPrint('App open ad load error: $error');
      _finishLoad(false);
    } catch (error) {
      if (kDebugMode) debugPrint('App open ad load error: $error');
      _finishLoad(false);
    }
  }

  void _finishLoad(bool success) {
    _isLoading = false;
    final completer = _loadCompleter;
    _loadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  /// Shows the ad when one is ready. [loadTimeout] bounds how long startup waits.
  /// A missing or failed ad never blocks the app.
  Future<bool> showAdIfAvailable({Duration? loadTimeout}) async {
    if (!AdService.instance.isSupported || _isShowing) return false;

    try {
      final loadFuture = loadAd();
      final loaded = loadTimeout == null
          ? await loadFuture
          : await loadFuture.timeout(
              loadTimeout,
              onTimeout: () => _appOpenAd != null,
            );
      final ad = _appOpenAd;
      if (ad == null || !loaded) return false;

      final completer = Completer<void>();
      var didShow = false;
      var released = false;
      _isShowing = true;

      void release(AppOpenAd shown) {
        if (released) return;
        released = true;
        _disposeAd(shown);
        _isShowing = false;
        if (!completer.isCompleted) completer.complete();
        loadAd();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: release,
        onAdFailedToShowFullScreenContent: (shown, error) => release(shown),
        onAdShowedFullScreenContent: (shown) {
          didShow = true;
        },
      );

      await ad.show().timeout(const Duration(seconds: 8));
      await completer.future.timeout(const Duration(seconds: 45));
      return didShow;
    } catch (error) {
      if (kDebugMode) debugPrint('App open ad show error: $error');
      _isShowing = false;
      final ad = _appOpenAd;
      if (ad != null) _disposeAd(ad);
      return false;
    }
  }

  void _disposeAd(AppOpenAd ad) {
    if (_appOpenAd == null) return;
    _appOpenAd = null;
    ad.dispose();
  }
}
