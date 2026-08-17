import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_sizes.dart';
import '../models/brand_profile_model.dart';

/// Wraps [SharedPreferences] for all lightweight app settings: onboarding flag,
/// brand profile, and export preferences. No account, no cloud — purely local.
class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  // --- Onboarding -----------------------------------------------------------

  Future<bool> isOnboardingDone() async =>
      (await _p).getBool(AppConstants.prefsOnboardingDone) ?? false;

  Future<void> setOnboardingDone() async =>
      (await _p).setBool(AppConstants.prefsOnboardingDone, true);

  // --- Brand profile --------------------------------------------------------

  Future<BrandProfileModel> loadBrand() async {
    final raw = (await _p).getString(AppConstants.prefsBrandProfile);
    if (raw == null) return const BrandProfileModel();
    try {
      return BrandProfileModel.fromMap(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const BrandProfileModel();
    }
  }

  Future<void> saveBrand(BrandProfileModel profile) async {
    await (await _p).setString(
        AppConstants.prefsBrandProfile, json.encode(profile.toMap()));
  }

  // --- Export preferences ---------------------------------------------------

  Future<String> exportQuality() async =>
      (await _p).getString(AppConstants.prefsExportQuality) ?? 'high';

  Future<void> setExportQuality(String q) async =>
      (await _p).setString(AppConstants.prefsExportQuality, q);

  Future<ExportSize> defaultExportSize() async =>
      ExportSizeInfo.fromKey((await _p).getString(AppConstants.prefsDefaultSize));

  Future<void> setDefaultExportSize(ExportSize size) async =>
      (await _p).setString(AppConstants.prefsDefaultSize, size.key);
}
