/// Spacing / radius design tokens plus the canonical poster export sizes.
class AppSizes {
  AppSizes._();

  static const double gap = 16;
  static const double gapSm = 8;
  static const double gapLg = 24;
  static const double radius = 18;
  static const double radiusSm = 12;
  static const double radiusLg = 28;
}

/// Canonical export sizes offered in the editor / export screen.
///
/// [posterPortrait] (4:5) is the default because it reads as a proper,
/// professional poster / flyer rather than a square social tile.
enum ExportSize {
  posterPortrait,
  instagramPost,
  instagramStory,
  facebookPost,
  a4Poster,
  custom,
}

extension ExportSizeInfo on ExportSize {
  String get label {
    switch (this) {
      case ExportSize.posterPortrait:
        return 'Poster (Portrait)';
      case ExportSize.instagramPost:
        return 'Instagram Post';
      case ExportSize.instagramStory:
        return 'Story / Reel';
      case ExportSize.facebookPost:
        return 'Facebook Post';
      case ExportSize.a4Poster:
        return 'A4 Poster';
      case ExportSize.custom:
        return 'Custom';
    }
  }

  String get sublabel {
    final d = dimensions;
    return '${d.width} × ${d.height}';
  }

  /// Storage key value.
  String get key => name;

  static ExportSize fromKey(String? key) =>
      ExportSize.values.firstWhere((e) => e.name == key,
          orElse: () => ExportSize.posterPortrait);

  ({int width, int height}) get dimensions {
    switch (this) {
      case ExportSize.posterPortrait:
        return (width: 1080, height: 1350);
      case ExportSize.instagramPost:
        return (width: 1080, height: 1080);
      case ExportSize.instagramStory:
        return (width: 1080, height: 1920);
      case ExportSize.facebookPost:
        return (width: 1200, height: 630);
      case ExportSize.a4Poster:
        return (width: 2480, height: 3508);
      case ExportSize.custom:
        return (width: 1080, height: 1080);
    }
  }

  double get aspectRatio {
    final d = dimensions;
    return d.width / d.height;
  }
}
