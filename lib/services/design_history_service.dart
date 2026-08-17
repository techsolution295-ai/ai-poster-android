import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/image_cache_helper.dart';
import '../models/design_model.dart';
import '../models/text_layer_model.dart';

/// Local, offline history of saved designs backed by a Hive box.
///
/// Each entry is stored as a plain `Map` keyed by design id, which avoids the
/// need for generated Hive TypeAdapters while remaining fully local.
class DesignHistoryService {
  DesignHistoryService._();
  static final DesignHistoryService instance = DesignHistoryService._();

  static const _uuid = Uuid();

  Box? _box;

  Future<Box> _open() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(AppConstants.designsBox);
    return _box!;
  }

  /// Inserts or updates a saved design. Returns its id.
  Future<String> save(SavedDesign design) async {
    final box = await _open();
    await box.put(design.id, design.toMap());
    return design.id;
  }

  /// Builds a [SavedDesign] (new or update) and persists it with an optional
  /// local preview image. Returns the saved record.
  Future<SavedDesign> savePoster({
    required PosterDesign design,
    String? id,
    String categoryId = '',
    String categoryName = '',
    String title = '',
    List<int>? previewBytes,
    DateTime? createdAt,
  }) async {
    final now = DateTime.now();
    final designId = (id != null && id.isNotEmpty) ? id : _uuid.v4();
    final existing =
        (id != null && id.isNotEmpty) ? await getById(designId) : null;

    var previewPath = existing?.previewPath ?? '';
    if (previewBytes != null && previewBytes.isNotEmpty) {
      previewPath = await ImageCacheHelper.saveBytes(
        previewBytes,
        'preview_$designId.jpg',
      );
    }

    final resolvedTitle = title.trim().isNotEmpty
        ? title.trim()
        : (existing?.title.isNotEmpty == true
            ? existing!.title
            : _titleFromDesign(design, categoryName));

    final backgroundPath = design.backgroundLocalPath ??
        existing?.backgroundPath ??
        '';

    final record = SavedDesign(
      id: designId,
      categoryId: categoryId.isNotEmpty
          ? categoryId
          : (existing?.categoryId ?? ''),
      categoryName: categoryName.isNotEmpty
          ? categoryName
          : (existing?.categoryName ?? ''),
      title: resolvedTitle,
      designJson: design.toMap(),
      previewPath: previewPath,
      backgroundPath: backgroundPath,
      createdAt: createdAt ?? existing?.createdAt ?? now,
      updatedAt: now,
    );

    await save(record);
    return record;
  }

  String _titleFromDesign(PosterDesign design, String categoryName) {
    for (final layer in design.layers) {
      if (layer.type == LayerType.text) {
        final t = layer.text.trim();
        if (t.isNotEmpty) {
          return t.length > 40 ? '${t.substring(0, 40)}…' : t;
        }
      }
    }
    if (categoryName.trim().isNotEmpty) return '$categoryName poster';
    return 'Untitled design';
  }

  Future<List<SavedDesign>> getAll() async {
    final box = await _open();
    final list = <SavedDesign>[];
    for (final value in box.values) {
      try {
        list.add(SavedDesign.fromMap(Map<String, dynamic>.from(value as Map)));
      } catch (e) {
        debugPrint('DesignHistoryService: skipping bad record ($e)');
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<SavedDesign?> getById(String id) async {
    final box = await _open();
    final value = box.get(id);
    if (value == null) return null;
    return SavedDesign.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<void> delete(String id) async {
    final existing = await getById(id);
    final box = await _open();
    await box.delete(id);
    await _deletePreviewFile(existing?.previewPath);
  }

  Future<void> clearAll() async {
    final all = await getAll();
    final box = await _open();
    await box.clear();
    for (final d in all) {
      await _deletePreviewFile(d.previewPath);
    }
  }

  Future<void> _deletePreviewFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('DesignHistoryService: preview delete failed ($e)');
    }
  }

  Future<List<SavedDesign>> search(String query) async {
    final all = await getAll();
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((d) =>
            d.title.toLowerCase().contains(q) ||
            d.categoryName.toLowerCase().contains(q))
        .toList();
  }
}
