import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// Anchored banner that sits under an app bar. Hidden until an ad loads.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const _retryInterval = Duration(seconds: 30);

  BannerAd? _bannerAd;
  bool _isLoading = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    if (!AdService.instance.isSupported) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBanner();
      _retryTimer = Timer.periodic(_retryInterval, (_) {
        if (!mounted || _bannerAd != null) return;
        _loadBanner();
      });
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBanner() {
    if (!AdService.instance.isSupported || _isLoading || _bannerAd != null) {
      return;
    }
    _isLoading = true;
    final ad = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _bannerAd = loaded as BannerAd;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoading = false;
          });
        },
      ),
    );
    ad.load().catchError((Object _) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        height: ad.size.height.toDouble(),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE8EAF2))),
        ),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(key: ValueKey(ad.hashCode), ad: ad),
        ),
      ),
    );
  }
}
