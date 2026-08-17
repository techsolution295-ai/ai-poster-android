import 'package:flutter/foundation.dart';

import '../core/constants/app_sizes.dart';
import '../models/brand_profile_model.dart';
import '../services/local_storage_service.dart';

/// App-wide, local-only state: the user's brand profile and export preferences.
/// No accounts, no network — everything is persisted via SharedPreferences.
class AppState extends ChangeNotifier {
  final _storage = LocalStorageService.instance;

  bool _loading = true;
  bool get loading => _loading;

  BrandProfileModel _brand = const BrandProfileModel();
  BrandProfileModel get brand => _brand;

  String _exportQuality = 'high';
  String get exportQuality => _exportQuality;

  ExportSize _defaultSize = ExportSize.posterPortrait;
  ExportSize get defaultSize => _defaultSize;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    _brand = await _storage.loadBrand();
    _exportQuality = await _storage.exportQuality();
    _defaultSize = await _storage.defaultExportSize();
    _loading = false;
    notifyListeners();
  }

  Future<void> saveBrand(BrandProfileModel profile) async {
    await _storage.saveBrand(profile);
    _brand = profile;
    notifyListeners();
  }

  Future<void> setExportQuality(String quality) async {
    await _storage.setExportQuality(quality);
    _exportQuality = quality;
    notifyListeners();
  }

  Future<void> setDefaultSize(ExportSize size) async {
    await _storage.setDefaultExportSize(size);
    _defaultSize = size;
    notifyListeners();
  }
}
