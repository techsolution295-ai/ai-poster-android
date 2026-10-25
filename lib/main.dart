import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_state.dart';
import 'services/ad_service.dart';
import 'services/app_open_ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    await Hive.initFlutter();
  } catch (_) {}

  // Free users see ads. Premium billing is not wired yet.
  AdService.instance.bind(isPro: () => false);

  // Consent → SDK → app-open request starts early so splash has a full 8s
  // fetch window. Interstitial is prefetched after the open ad (policy).
  if (AdService.instance.isSupported) {
    unawaited(
      AdService.instance.ensureReady().then((_) {
        if (AdService.instance.canRequestAds) {
          unawaited(AppOpenAdManager.instance.loadAd());
        }
      }),
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: const PosterMakerApp(),
    ),
  );
}
