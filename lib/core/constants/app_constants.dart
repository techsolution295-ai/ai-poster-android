/// Global, non-secret constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Poster Maker';
  static const String appTagline = 'Flyer & Thumbnail Maker';
  static const String packageName = 'com.postermaker.graphicdesign.flyer.editor';

  // Legal / support (Play Store listing).
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/app-bounties/home';
  static const String termsUrl = 'https://sites.google.com/view/appbounties/home';
  static const String supportEmail = 'supportmateen@gmail.com';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  // Local asset data files.
  static const String categoriesAsset = 'assets/data/categories.json';
  static const String keywordsAsset = 'assets/data/keywords.json';
  static const String layoutsAsset = 'assets/data/layouts.json';
  static const String defaultTextsAsset = 'assets/data/default_texts.json';
  static const String homeBannerAsset =
      'assets/images/home_top_banner.png';
  static const String appIconAsset = 'assets/images/app_icon.png';
  static const String historyBannerAsset =
      'assets/images/history_top_banner.png';
  static const String settingsBannerAsset =
      'assets/images/settings_top_banner.png';

  // SharedPreferences keys.
  static const String prefsOnboardingDone = 'onboarding_done';
  static const String prefsBrandProfile = 'brand_profile';
  static const String prefsExportQuality = 'export_quality';
  static const String prefsDefaultSize = 'default_export_size';

  // Hive boxes.
  static const String designsBox = 'designs_box';
  static const String templatesCacheBox = 'templates_cache_box';

  static const int templatesPerCategory = 20;
}
