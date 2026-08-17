import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local database for design history.
  await Hive.initFlutter();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: const PosterMakerApp(),
    ),
  );
}
