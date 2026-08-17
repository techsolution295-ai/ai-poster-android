import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/image_cache_helper.dart';
import '../engine/layout_engine.dart';
import '../engine/layout_loader.dart';
import '../models/brand_profile_model.dart';
import '../models/category_model.dart';
import '../models/design_model.dart';
import '../models/template_model.dart';
import 'pexels_service.dart';
import 'pixabay_service.dart';
import 'stock_image.dart';

/// The heart of the app's "auto template" system.
///
/// It loads local category/keyword/default-text JSON, fetches free stock images
/// from Pexels/Pixabay (or key-less demo imagery), then pairs each image with
/// one of the 15 local layouts to produce editable templates — no template
/// images are ever hand-authored. Generated templates are cached locally so the
/// gallery still works offline.
class TemplateGeneratorService {
  TemplateGeneratorService._();
  static final TemplateGeneratorService instance = TemplateGeneratorService._();

  final _rand = Random();

  List<CategoryModel>? _categories;
  Map<String, List<String>>? _keywords;
  Map<String, dynamic>? _defaultTexts;

  // ---- Local JSON loading --------------------------------------------------

  Future<void> _ensureData() async {
    if (_categories != null) return;
    final catRaw = await rootBundle.loadString(AppConstants.categoriesAsset);
    final kwRaw = await rootBundle.loadString(AppConstants.keywordsAsset);
    final dtRaw = await rootBundle.loadString(AppConstants.defaultTextsAsset);

    _categories = (json.decode(catRaw) as List)
        .map((e) => CategoryModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    _keywords = (json.decode(kwRaw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
    );

    _defaultTexts = json.decode(dtRaw) as Map<String, dynamic>;
    await LayoutLoader.loadAll();
  }

  Future<List<CategoryModel>> getCategories() async {
    await _ensureData();
    return _categories ?? [];
  }

  CategoryModel? categoryById(String id) {
    if (_categories == null) return null;
    for (final c in _categories!) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---- Template generation -------------------------------------------------

  /// Generates up to [count] templates for [categoryId]. Tries live APIs first,
  /// then key-less demo images, then falls back to a local cache when offline.
  Future<List<TemplateModel>> generateTemplates(
    String categoryId, {
    int count = AppConstants.templatesPerCategory,
    List<String>? keywordOverrides,
    Map<String, String>? textOverrides,
  }) async {
    await _ensureData();

    final images = await _fetchImages(categoryId, count, keywordOverrides: keywordOverrides);
    if (images.isNotEmpty) {
      final templates =
          _buildTemplates(categoryId, images, count, textOverrides: textOverrides);
      await _cacheTemplates(categoryId, templates);
      return templates;
    }

    // Offline with no fresh images -> use last cached templates if we have any.
    return _loadCachedTemplates(categoryId);
  }

  Future<List<StockImage>> _fetchImages(
    String categoryId,
    int count, {
    List<String>? keywordOverrides,
  }) async {
    final keywords = (keywordOverrides != null && keywordOverrides.isNotEmpty)
        ? keywordOverrides
        : (_keywords?[categoryId] ?? const []);
    final results = <StockImage>[];

    for (final keyword in keywords) {
      if (results.length >= count) break;
      final perKeyword = (count / keywords.length).ceil() + 2;
      results.addAll(await PexelsService.instance.search(keyword, perPage: perKeyword));
      if (results.length < count) {
        results.addAll(await PixabayService.instance.search(keyword, perPage: perKeyword));
      }
    }

    // No keys configured (or all failed): use free, key-less demo photos so the
    // whole flow is testable without signing up. (Requires internet.)
    if (results.isEmpty) {
      for (final keyword in keywords) {
        results.addAll(_demoImages(keyword, count: (count / keywords.length).ceil() + 1));
      }
    }

    results.shuffle(_rand);
    return results.take(count).toList();
  }

  List<TemplateModel> _buildTemplates(
    String categoryId,
    List<StockImage> images,
    int count, {
    Map<String, String>? textOverrides,
  }) {
    final dt = _defaultTexts?[categoryId] as Map<String, dynamic>? ?? {};
    final titles = _list(dt['titles']);
    final subtitles = _list(dt['subtitles']);
    final details = _list(dt['details']);
    final prices = _list(dt['prices']);

    final templates = <TemplateModel>[];
    for (var i = 0; i < images.length && i < count; i++) {
      final img = images[i];
      final layoutId = LayoutLoader.idForIndex((i % LayoutLoader.count) + 1);
      final title = textOverrides?['title'] ?? _pick(titles, i, 'Your Title Here');
      templates.add(TemplateModel(
        id: '${categoryId}_$i',
        categoryId: categoryId,
        title: title,
        layoutId: layoutId,
        backgroundUrl: img.url,
        sourceName: img.sourceName,
        sourcePageUrl: img.sourcePageUrl,
        photographerName: img.photographerName,
        defaultTexts: {
          'title': title,
          'subtitle': textOverrides?['subtitle'] ?? _pick(subtitles, i, ''),
          'details': textOverrides?['details'] ?? _pick(details, i, ''),
          'price': textOverrides?['price'] ?? _pick(prices, i, ''),
          'contact': textOverrides?['contact'] ?? '+1 234 567 890',
        },
        defaultFont: 'Poppins',
      ));
    }
    return templates;
  }

  /// Build templates from externally provided images (e.g. AI image APIs),
  /// while still using our local layouts + text system.
  Future<List<TemplateModel>> buildTemplatesFromStockImages(
    String categoryId,
    List<StockImage> images, {
    Map<String, String>? textOverrides,
  }) async {
    await _ensureData();
    if (images.isEmpty) return const [];
    return _buildTemplates(
      categoryId,
      images,
      images.length,
      textOverrides: textOverrides,
    );
  }

  // ---- Build an editable design from a template ----------------------------

  /// Produces the editable [PosterDesign] for [template], auto-filling the
  /// user's [brand] and caching Pixabay backgrounds locally (per Pixabay terms).
  Future<PosterDesign> buildDesign(
    TemplateModel template, {
    BrandProfileModel? brand,
    double aspectRatio = 1.0,
    bool cacheBackground = true,
  }) async {
    await _ensureData();
    final layoutConfig = await LayoutLoader.load(template.layoutId);

    // Pixabay images must not be hotlinked permanently -> cache locally when the
    // design is actually opened/saved. Previews skip this ([cacheBackground]).
    String? backgroundUrl = template.backgroundUrl.isNotEmpty ? template.backgroundUrl : null;
    String? backgroundLocalPath;
    if (cacheBackground && template.sourceName == 'Pixabay' && backgroundUrl != null) {
      backgroundLocalPath = await ImageCacheHelper.cache(backgroundUrl);
      if (backgroundLocalPath != null) backgroundUrl = null;
    }

    final design = LayoutEngine.buildDesign(
      layoutConfig: layoutConfig,
      backgroundUrl: backgroundUrl,
      backgroundLocalPath: backgroundLocalPath,
      aspectRatio: aspectRatio,
      texts: template.defaultTexts,
      brand: brand,
      fontFamily: template.defaultFont,
      sourceName: template.sourceName,
      sourcePageUrl: template.sourcePageUrl,
      photographerName: template.photographerName,
    );
    return design;
  }

  /// Lightweight design for gallery thumbnails: renders via the layout engine
  /// at small size but does NOT download images (uses the URL directly).
  Future<PosterDesign> buildPreviewDesign(
    TemplateModel template, {
    BrandProfileModel? brand,
    double aspectRatio = 1.0,
  }) =>
      buildDesign(template,
          brand: brand, aspectRatio: aspectRatio, cacheBackground: false);

  // ---- Demo (key-less) imagery --------------------------------------------

  List<StockImage> _demoImages(String keyword, {int count = 4}) {
    final seed = keyword.hashCode.abs();
    return List.generate(count, (i) {
      final s = '$seed$i';
      return StockImage(
        url: 'https://picsum.photos/seed/$s/1080/1080',
        previewUrl: 'https://picsum.photos/seed/$s/500/500',
        sourceName: 'Lorem Picsum (demo)',
        sourcePageUrl: 'https://picsum.photos',
        photographerName: null,
        licenseNote: 'Demo placeholder image (Lorem Picsum). Add Pexels/Pixabay '
            'API keys for real category photos.',
        requiresLocalCache: false,
      );
    });
  }

  // ---- Local template cache (Hive) -----------------------------------------

  Future<void> _cacheTemplates(String categoryId, List<TemplateModel> templates) async {
    try {
      final box = await Hive.openBox(AppConstants.templatesCacheBox);
      await box.put(categoryId, templates.map((t) => t.toMap()).toList());
    } catch (e) {
      debugPrint('Template cache write failed: $e');
    }
  }

  Future<List<TemplateModel>> _loadCachedTemplates(String categoryId) async {
    try {
      final box = await Hive.openBox(AppConstants.templatesCacheBox);
      final raw = box.get(categoryId);
      if (raw is List) {
        return raw
            .map((e) => TemplateModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('Template cache read failed: $e');
    }
    return [];
  }

  // ---- helpers -------------------------------------------------------------

  List<String> _list(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  String _pick(List<String> list, int i, String fallback) =>
      list.isEmpty ? fallback : list[i % list.length];
}
