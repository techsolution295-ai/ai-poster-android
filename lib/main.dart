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

  // Local database for design history.
  await Hive.initFlutter();

  if (AdService.instance.isSupported) {
    // Start the SDK during splash. First install can take several seconds,
    // so this must not be abandoned if it is still running.
    unawaited(AdService.instance.ensureInitialized().then((_) {
      unawaited(AppOpenAdManager.instance.loadAd());
    }));
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: const PosterMakerApp(),
    ),
  );
}
