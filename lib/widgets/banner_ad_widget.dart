import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// Banner under the app bar — same strip pattern as google-lens-ios.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const double _height = 56;

  BannerAd? _banner;
  BannerAd? _loadingAd;
  bool _isLoading = false;
  bool _disposed = false;
  Timer? _retryTimer;

  bool get _allowed =>
      AdService.instance.isSupported &&
      AdService.instance.sdkReady &&
      !AdService.instance.isPro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      _load();
      _armRetry();
    });
  }

  void _armRetry() {
    // Only retry failed loads. AdMob refreshes a live banner itself.
    _retryTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted || _banner != null || _disposed || !_allowed) return;
      if (!AdService.instance.canRequestAds) return;
      _load();
    });
  }

  void _load() {
    if (_disposed || _isLoading || _banner != null) return;
    if (!_allowed || !AdService.instance.canRequestAds) return;
    _isLoading = true;
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AdService.instance.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (_disposed || !mounted || !_allowed) {
            if (!_disposed) loaded.dispose();
            return;
          }
          setState(() {
            _banner = loaded as BannerAd;
            _loadingAd = null;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          if (!_disposed) failed.dispose();
          if (!mounted || _disposed) return;
          setState(() {
            _banner = null;
            _loadingAd = null;
            _isLoading = false;
          });
        },
      ),
    );
    _loadingAd = ad;
    ad.load();
  }

  void _drop() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _banner?.dispose();
    _loadingAd?.dispose();
    _banner = null;
    _loadingAd = null;
    _isLoading = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_allowed) {
      if (_banner != null || _loadingAd != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _drop();
        });
      }
      return const SizedBox.shrink();
    }

    final banner = _banner;
    return Material(
      color: Colors.white,
      child: Container(
        height: _height,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        alignment: Alignment.center,
        child: banner == null
            ? const _BannerPlaceholder()
            : SizedBox(
                width: banner.size.width.toDouble(),
                height: banner.size.height.toDouble(),
                child: AdWidget(key: ValueKey(banner.hashCode), ad: banner),
              ),
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
