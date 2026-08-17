import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled layout definitions from `assets/data/layouts.json`.
///
/// Layouts are cached in memory after first load. This is the single source of
/// truth for the 15 reusable layout styles used by the template generator and
/// the editor — no network required.
class LayoutLoader {
  LayoutLoader._();

  static const String assetPath = 'assets/data/layouts.json';

  static List<Map<String, dynamic>>? _all;
  static final Map<String, Map<String, dynamic>> _byId = {};

  /// Zero-padded layout id for an index (1 -> `layout_01`).
  static String idForIndex(int index) =>
      'layout_${index.toString().padLeft(2, '0')}';

  static Future<List<Map<String, dynamic>>> loadAll() async {
    if (_all != null) return _all!;
    final raw = await rootBundle.loadString(assetPath);
    final list = (json.decode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _all = list;
    for (final l in list) {
      final id = l['id']?.toString();
      if (id != null) _byId[id] = l;
    }
    return list;
  }

  /// Returns a single layout config by id (loads all on first call).
  static Future<Map<String, dynamic>> load(String layoutId) async {
    if (_byId.isEmpty) await loadAll();
    final cfg = _byId[layoutId];
    if (cfg != null) return cfg;
    // Fall back to the first layout if the id is unknown.
    final all = _all ?? await loadAll();
    return all.isNotEmpty ? all.first : {'id': layoutId, 'layers': []};
  }

  static int get count => _all?.length ?? 15;
}
