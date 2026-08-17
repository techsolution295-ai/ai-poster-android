import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/design_model.dart';
import '../models/text_layer_model.dart';

/// Holds and mutates the [PosterDesign] currently being edited, plus selection
/// and undo/redo history. Backs the Poster Editor screen.
class EditorController extends ChangeNotifier {
  EditorController(PosterDesign design)
      : _design = design,
        _initialSnapshot = design.toMap();

  static const _uuid = Uuid();
  static const int _historyLimit = 40;

  PosterDesign _design;
  final Map<String, dynamic> _initialSnapshot;
  PosterDesign get design => _design;

  String? _selectedId;
  String? get selectedId => _selectedId;

  final List<Map<String, dynamic>> _undo = [];
  final List<Map<String, dynamic>> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  PosterLayer? get selected {
    if (_selectedId == null) return null;
    for (final l in _design.layers) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  // ---- Selection -----------------------------------------------------------

  void select(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  void deselect() => select(null);

  // ---- History -------------------------------------------------------------

  /// Records the current state so it can be undone. Call this at the *start* of
  /// any user action (before mutating), including at the beginning of a drag.
  void pushHistory() {
    _undo.add(_design.toMap());
    if (_undo.length > _historyLimit) _undo.removeAt(0);
    _redo.clear();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_design.toMap());
    _design = PosterDesign.fromMap(_undo.removeLast());
    _selectedId = null;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_design.toMap());
    _design = PosterDesign.fromMap(_redo.removeLast());
    _selectedId = null;
    notifyListeners();
  }

  /// Restore the poster to how it looked when the editor first opened.
  void resetToInitial() {
    _undo.clear();
    _redo.clear();
    _design = PosterDesign.fromMap(Map<String, dynamic>.from(_initialSnapshot));
    _selectedId = null;
    notifyListeners();
  }

  // ---- Add layers ----------------------------------------------------------

  void addText({String text = 'Tap to edit'}) {
    pushHistory();
    final layer = PosterLayer(
      id: _uuid.v4(),
      type: LayerType.text,
      text: text,
      x: 0.15,
      y: 0.4,
      width: 0.7,
      height: 0.12,
      fontSizeFactor: 0.07,
      colorHex: '#FFFFFFFF',
    );
    _design.layers.add(layer);
    _selectedId = layer.id;
    notifyListeners();
  }

  void addShape(String shape) {
    pushHistory();
    final layer = PosterLayer(
      id: _uuid.v4(),
      type: LayerType.shape,
      shape: shape,
      x: 0.3,
      y: 0.4,
      width: 0.4,
      height: 0.2,
      fillHex: '#996C2BD9',
    );
    _design.layers.add(layer);
    _selectedId = layer.id;
    notifyListeners();
  }

  void addIcon(String iconName) {
    pushHistory();
    final layer = PosterLayer(
      id: _uuid.v4(),
      type: LayerType.icon,
      iconName: iconName,
      x: 0.4,
      y: 0.4,
      width: 0.2,
      height: 0.2,
      colorHex: '#FFFFFFFF',
    );
    _design.layers.add(layer);
    _selectedId = layer.id;
    notifyListeners();
  }

  void addImage({
    String? url,
    String? localPath,
    LayerRole role = LayerRole.none,
    bool sticker = false,
  }) {
    pushHistory();
    final isLogo = role == LayerRole.logo;
    final layer = PosterLayer(
      id: _uuid.v4(),
      type: LayerType.image,
      role: role,
      imageUrl: url,
      localPath: localPath,
      x: isLogo ? 0.06 : 0.28,
      y: isLogo ? 0.06 : 0.28,
      width: isLogo ? 0.18 : sticker ? 0.38 : 0.5,
      height: isLogo ? 0.18 : sticker ? 0.38 : 0.4,
      imageFit: isLogo || sticker ? BoxFit.contain : BoxFit.cover,
    );
    _design.layers.add(layer);
    _selectedId = layer.id;
    notifyListeners();
  }

  // ---- Modify selected -----------------------------------------------------

  void deleteSelected() {
    final layer = selected;
    if (layer == null) return;
    pushHistory();
    _design.layers.removeWhere((l) => l.id == layer.id);
    _selectedId = null;
    notifyListeners();
  }

  void bringToFront() {
    final layer = selected;
    if (layer == null) return;
    pushHistory();
    _design.layers
      ..removeWhere((l) => l.id == layer.id)
      ..add(layer);
    notifyListeners();
  }

  void sendToBack() {
    final layer = selected;
    if (layer == null) return;
    pushHistory();
    _design.layers
      ..removeWhere((l) => l.id == layer.id)
      ..insert(0, layer);
    notifyListeners();
  }

  /// Live geometry drag (no history push — caller pushes on gesture start).
  void dragSelectedBy(double dxFraction, double dyFraction) {
    final l = selected;
    if (l == null || l.locked) return;
    l.x = (l.x + dxFraction).clamp(-0.5, 1.0);
    l.y = (l.y + dyFraction).clamp(-0.5, 1.0);
    notifyListeners();
  }

  /// Pinch-zoom from gesture baseline, keeping the layer centered.
  void scaleLayerFromCenter({
    required double baseX,
    required double baseY,
    required double baseW,
    required double baseH,
    required double baseFontSize,
    required double scaleFactor,
  }) {
    final l = selected;
    if (l == null || l.locked) return;
    final s = scaleFactor.clamp(0.15, 6.0);
    final cx = baseX + baseW / 2;
    final cy = baseY + baseH / 2;
    final newW = (baseW * s).clamp(0.04, 2.0);
    final newH = (baseH * s).clamp(0.02, 2.0);
    l.x = (cx - newW / 2).clamp(-0.5, 1.0);
    l.y = (cy - newH / 2).clamp(-0.5, 1.0);
    l.width = newW;
    l.height = newH;
    if (l.type == LayerType.text) {
      l.fontSizeFactor = (baseFontSize * s).clamp(0.01, 0.5);
    }
    notifyListeners();
  }

  void setLayerRotationDegrees(double degrees) {
    final l = selected;
    if (l == null || l.locked) return;
    l.rotation = degrees;
    notifyListeners();
  }

  /// Resize using normalised deltas; accounts for caller applying local-axis conversion.
  void resizeLayerLive(double dwNorm, double dhNorm) {
    final l = selected;
    if (l == null || l.locked) return;
    final oldW = l.width;
    l.width = (l.width + dwNorm).clamp(0.04, 2.0);
    l.height = (l.height + dhNorm).clamp(0.02, 2.0);
    if (l.type == LayerType.text && oldW > 0) {
      l.fontSizeFactor = (l.fontSizeFactor * (l.width / oldW)).clamp(0.01, 0.5);
    }
    notifyListeners();
  }

  /// Resize the selected layer by a pixel delta applied to its bottom-right
  /// corner (top-left stays anchored). Text scales its font with the width.
  void resizeSelectedByPixels(double dxPx, double dyPx, double canvasW, double canvasH) {
    final l = selected;
    if (l == null || l.locked) return;
    final oldW = l.width;
    final newW = (l.width + dxPx / canvasW).clamp(0.04, 2.0);
    l.width = newW;
    l.height = (l.height + dyPx / canvasH).clamp(0.02, 2.0);
    if (l.type == LayerType.text && oldW > 0) {
      l.fontSizeFactor = (l.fontSizeFactor * (newW / oldW)).clamp(0.01, 0.5);
    }
    notifyListeners();
  }

  void scaleSelected(double factor) {
    final l = selected;
    if (l == null || l.locked) return;
    l.width = (l.width * factor).clamp(0.03, 2.0);
    l.height = (l.height * factor).clamp(0.03, 2.0);
    if (l.type == LayerType.text) {
      l.fontSizeFactor = (l.fontSizeFactor * factor).clamp(0.01, 0.5);
    }
    notifyListeners();
  }

  void rotateSelected(double radians) {
    final l = selected;
    if (l == null || l.locked) return;
    l.rotation = radians * 180 / 3.1415926535;
    notifyListeners();
  }

  // Text-specific edits (each records history).
  void setText(String value) => _mutate((l) => l.text = value);

  /// Live text update while typing — does not push undo history per keystroke.
  void setTextLive(String value) {
    final l = selected;
    if (l == null) return;
    l.text = value;
    notifyListeners();
  }

  void beginTextEditSession() => pushHistory();

  void duplicateSelected() {
    final layer = selected;
    if (layer == null) return;
    pushHistory();
    final copy = PosterLayer.fromMap(layer.toMap())
      ..id = _uuid.v4()
      ..x = (layer.x + 0.02).clamp(-0.5, 1.0)
      ..y = (layer.y + 0.02).clamp(-0.5, 1.0);
    _design.layers.add(copy);
    _selectedId = copy.id;
    notifyListeners();
  }
  void setFont(String family) => _mutate((l) => l.fontFamily = family);
  void setTextColor(String hex) => _mutate((l) => l.colorHex = hex);
  void setFillColor(String hex) => _mutate((l) => l.fillHex = hex);
  void setFontSizeFactor(double v) =>
      _mutate((l) => l.fontSizeFactor = v.clamp(0.01, 0.5));
  void toggleBold() => _mutate((l) => l.bold = !l.bold);
  void toggleItalic() => _mutate((l) => l.italic = !l.italic);
  void setAlign(TextAlign a) => _mutate((l) => l.align = a);
  void setOpacity(double v) => _mutate((l) => l.opacity = v.clamp(0.0, 1.0));
  void setLetterSpacing(double v) => _mutate((l) => l.letterSpacing = v);

  void _mutate(void Function(PosterLayer) fn) {
    final l = selected;
    if (l == null) return;
    pushHistory();
    fn(l);
    notifyListeners();
  }

  // ---- Background / overlay ------------------------------------------------

  void setBackgroundUrl(String url, {String? sourceName, String? sourcePageUrl, String? photographer}) {
    pushHistory();
    _design.backgroundUrl = url;
    _design.backgroundLocalPath = null;
    if (sourceName != null) _design.sourceName = sourceName;
    if (sourcePageUrl != null) _design.sourcePageUrl = sourcePageUrl;
    _design.photographerName = photographer;
    notifyListeners();
  }

  void setBackgroundLocal(String path) {
    pushHistory();
    _design.backgroundLocalPath = path;
    _design.backgroundUrl = null;
    _design.sourceName = 'Your device';
    _design.sourcePageUrl = '';
    _design.photographerName = null;
    notifyListeners();
  }

  void setBackgroundColor(String hex) {
    pushHistory();
    _design.backgroundColorHex = hex;
    _design.backgroundUrl = null;
    _design.backgroundLocalPath = null;
    notifyListeners();
  }

  void setOverlay(String fromHex, {String? toHex}) {
    pushHistory();
    _design.overlayHex = fromHex;
    _design.overlayGradientToHex = toHex;
    notifyListeners();
  }

  void setAspectRatio(double ratio) {
    pushHistory();
    _design.aspectRatio = ratio;
    notifyListeners();
  }
}
