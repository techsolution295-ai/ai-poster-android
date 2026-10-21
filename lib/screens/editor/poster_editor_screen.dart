import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/icon_resolver.dart';
import '../../core/utils/image_cache_helper.dart';
import '../../core/utils/ui_helpers.dart';
import '../../models/category_model.dart';
import '../../models/design_model.dart';
import '../../models/template_model.dart';
import '../../models/text_layer_model.dart';
import '../../providers/app_state.dart';
import '../../providers/editor_controller.dart';
import '../../services/design_history_service.dart';
import '../../services/export_service.dart';
import '../../services/stock_image.dart';
import '../../services/template_generator_service.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/color_swatch_picker.dart';
import '../../widgets/loading_skeleton.dart';
import '../background/background_change_screen.dart';
import '../export/export_screen.dart';
import 'widgets/editor_canvas.dart';
import 'widgets/editor_sheet_scaffold.dart';
import 'widgets/editor_style_panel.dart';
import 'widgets/editor_tool_button.dart';
import 'widgets/sticker_picker_sheet.dart';

/// Poster editor with contextual bottom chrome — matches reference app flow:
/// main toolbar when idle, selection toolbar when layer selected,
/// inline text field when editing text content.
class PosterEditorScreen extends StatefulWidget {
  final TemplateModel? template;
  final CategoryModel? category;
  final SavedDesign? savedDesign;

  const PosterEditorScreen({
    super.key,
    this.template,
    this.category,
    this.savedDesign,
  });

  @override
  State<PosterEditorScreen> createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();

  EditorController? _controller;
  bool _loading = true;
  String _categoryId = '';
  String _categoryName = '';
  String? _historyId;
  String _title = '';
  bool _saving = false;
  bool _openFailed = false;
  ExportSize _size = ExportSize.instagramPost;

  bool _textEditMode = false;
  TextEditingController? _textModeController;
  FocusNode? _textModeFocusNode;
  bool _showStylePanel = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _textModeController?.dispose();
    _textModeFocusNode?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final appState = context.read<AppState>();
      _size = appState.defaultSize;

      final PosterDesign design;
      if (widget.savedDesign != null) {
        final s = widget.savedDesign!;
        design = s.design;
        _categoryId = s.categoryId;
        _categoryName = s.categoryName;
        _historyId = s.id;
        _title = s.title;
        _size = _closestSize(design.aspectRatio);
      } else {
        final t = widget.template;
        if (t == null) throw StateError('No poster to open.');
        _categoryId = t.categoryId;
        _categoryName = widget.category?.name ?? '';
        design = await TemplateGeneratorService.instance.buildDesign(
          t,
          brand: appState.brand,
          aspectRatio: _size.aspectRatio,
        );
      }
      if (!mounted) return;
      setState(() {
        _controller = EditorController(design);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _openFailed = true;
      });
    }
  }

  ExportSize _closestSize(double ratio) {
    ExportSize best = ExportSize.instagramPost;
    double diff = double.infinity;
    for (final s in ExportSize.values) {
      final d = (s.aspectRatio - ratio).abs();
      if (d < diff) {
        diff = d;
        best = s;
      }
    }
    return best;
  }

  EditorController get _c => _controller!;

  PosterLayer? get _selected => _c.selected;

  void _clearSelection() {
    _finishTextMode(removeIfEmpty: true);
    setState(() {
      _showStylePanel = false;
      _c.deselect();
    });
  }

  void _enterTextEdit() {
    final layer = _selected;
    if (layer == null || layer.type != LayerType.text) return;

    _textModeController?.dispose();
    _textModeFocusNode?.dispose();
    _c.beginTextEditSession();
    _textModeController = TextEditingController(text: layer.text);
    _textModeFocusNode = FocusNode();

    setState(() {
      _textEditMode = true;
      _showStylePanel = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textModeFocusNode?.requestFocus();
    });
  }

  void _syncTextLive(String value) => _c.setTextLive(value);

  void _finishTextMode({bool removeIfEmpty = false}) {
    if (!_textEditMode) return;
    final layer = _selected;
    final text = _textModeController?.text.trim() ?? '';

    if (removeIfEmpty && layer != null && layer.type == LayerType.text && text.isEmpty) {
      _c.deleteSelected();
    } else if (layer != null && layer.type == LayerType.text) {
      _c.setTextLive(text);
    }

    _textModeController?.dispose();
    _textModeFocusNode?.dispose();
    _textModeController = null;
    _textModeFocusNode = null;

    setState(() => _textEditMode = false);
  }

  void _startTextMode() {
    _c.addText();
    _enterTextEdit();
  }

  Future<void> _changeBackground() async {
    final query = widget.category?.name ?? _categoryName;
    final result = await Navigator.push<StockImage>(
      context,
      MaterialPageRoute(
        builder: (_) => BackgroundChangeScreen(initialQuery: query, categoryId: _categoryId),
      ),
    );
    if (result == null || !mounted) return;
    if (result.requiresLocalCache) {
      final path = await ImageCacheHelper.cache(result.url);
      if (path != null) {
        _c.setBackgroundLocal(path);
      } else {
        _c.setBackgroundUrl(
          result.url,
          sourceName: result.sourceName,
          sourcePageUrl: result.sourcePageUrl,
        );
      }
      _c.design.sourceName = result.sourceName;
      _c.design.sourcePageUrl = result.sourcePageUrl;
      _c.design.photographerName = result.photographerName;
    } else {
      _c.setBackgroundUrl(
        result.url,
        sourceName: result.sourceName,
        sourcePageUrl: result.sourcePageUrl,
        photographer: result.photographerName,
      );
    }
  }

  Future<void> _openStickerPicker() async {
    final url = await StickerPickerSheet.show(context);
    if (url == null || !mounted) return;
    _c.addImage(url: url, sticker: true);
  }

  Future<void> _pickImage({required LayerRole role}) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (file == null || !mounted) return;
      _c.addImage(localPath: file.path, role: role);
    } catch (_) {
      if (mounted) UiHelpers.showSnack(context, 'Could not pick image.', error: true);
    }
  }

  Future<void> _replaceSelectedImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (file == null || !mounted) return;
      final layer = _selected;
      if (layer == null || layer.type != LayerType.image) return;
      _c.pushHistory();
      layer.localPath = file.path;
      layer.imageUrl = null;
      _c.select(layer.id);
    } catch (_) {
      if (mounted) UiHelpers.showSnack(context, 'Could not pick image.', error: true);
    }
  }

  void _addShape() {
    UiHelpers.showRoundedSheet(
      context,
      _PickerSheet(
        title: 'Add shape',
        items: const [
          _PickItem('rounded', 'Rounded', Icons.rectangle_rounded),
          _PickItem('rect', 'Rectangle', Icons.crop_square),
          _PickItem('circle', 'Circle', Icons.circle),
          _PickItem('line', 'Line', Icons.remove),
        ],
        onSelected: (v) {
          Navigator.pop(context);
          _c.addShape(v);
        },
      ),
    );
  }

  void _addIcon() {
    UiHelpers.showRoundedSheet(
      context,
      _PickerSheet(
        title: 'Add icon',
        items: [
          for (final name in IconResolver.availableNames)
            _PickItem(name, name, IconResolver.resolve(name)),
        ],
        onSelected: (v) {
          Navigator.pop(context);
          _c.addIcon(v);
        },
      ),
    );
  }

  void _openTextColorSheet() {
    final layer = _selected;
    if (layer == null || layer.type != LayerType.text) return;
    UiHelpers.showRoundedSheet(
      context,
      AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final l = _c.selected;
          if (l == null) return const SizedBox.shrink();
          return EditorSheetScaffold(
            title: 'Text colour',
            maxHeightFraction: 0.38,
            child: SingleChildScrollView(
              child: ColorSwatchPicker(
                selectedHex: l.colorHex,
                onSelected: _c.setTextColor,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFillColorSheet() {
    final layer = _selected;
    if (layer == null) return;
    final isText = layer.type == LayerType.text || layer.type == LayerType.icon;
    UiHelpers.showRoundedSheet(
      context,
      AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final l = _c.selected;
          if (l == null) return const SizedBox.shrink();
          return EditorSheetScaffold(
            title: isText ? 'Text colour' : 'Fill colour',
            maxHeightFraction: 0.38,
            child: SingleChildScrollView(
              child: ColorSwatchPicker(
                selectedHex: isText ? l.colorHex : l.fillHex,
                onSelected: (hex) {
                  if (isText) {
                    _c.setTextColor(hex);
                  } else {
                    _c.setFillColor(hex);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFontSizeSheet() {
    final layer = _selected;
    if (layer == null || layer.type != LayerType.text) return;
    UiHelpers.showRoundedSheet(
      context,
      AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final l = _c.selected;
          if (l == null) return const SizedBox.shrink();
          final value = l.fontSizeFactor.clamp(0.02, 0.3);
          return EditorSheetScaffold(
            title: 'Text size',
            maxHeightFraction: 0.32,
            child: Column(
              children: [
                Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: value,
                  min: 0.02,
                  max: 0.3,
                  onChanged: _c.setFontSizeFactor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editOverlay() {
    UiHelpers.showRoundedSheet(
      context,
      AnimatedBuilder(
        animation: _c,
        builder: (context, _) => EditorSheetScaffold(
          title: 'Overlay',
          maxHeightFraction: 0.38,
          child: SingleChildScrollView(
            child: ColorSwatchPicker(
              selectedHex: _c.design.overlayHex,
              includeTransparent: true,
              onSelected: (hex) => _c.setOverlay(hex, toHex: _c.design.overlayGradientToHex),
            ),
          ),
        ),
      ),
    );
  }

  void _chooseSize() {
    UiHelpers.showRoundedSheet(
      context,
      EditorSheetScaffold(
        title: 'Poster size',
        maxHeightFraction: 0.55,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in ExportSize.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s == _size ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                title: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(s.sublabel, style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _size = s);
                  _c.setAspectRatio(s.aspectRatio);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<List<int>?> _capturePreview({int width = 600}) async {
    _finishTextMode(removeIfEmpty: true);
    _c.deselect();
    setState(() => _showStylePanel = false);
    await WidgetsBinding.instance.endOfFrame;
    try {
      return await ExportService.instance.capture(
        boundaryKey: _boundaryKey,
        targetWidth: width,
        format: ExportFormat.jpg,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _resetDesign() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset design?'),
        content: const Text('All changes will be removed and the original poster will be restored.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    _finishTextMode(removeIfEmpty: false);
    _c.resetToInitial();
    setState(() => _showStylePanel = false);
    if (mounted) UiHelpers.showSnack(context, 'Design reset.');
  }

  Widget _appBarIcon({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    Widget? child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: child ?? Icon(icon, size: 22, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_saving || _controller == null) return;
    setState(() => _saving = true);
    try {
      final preview = await _capturePreview();
      final saved = await DesignHistoryService.instance.savePoster(
        design: _c.design,
        id: _historyId,
        categoryId: _categoryId,
        categoryName: _categoryName,
        title: _title,
        previewBytes: preview,
      );
      if (!mounted) return;
      setState(() {
        _historyId = saved.id;
        _title = saved.title;
      });
      UiHelpers.showSnack(context, 'Saved to History');
    } catch (e) {
      if (mounted) {
        UiHelpers.showSnack(context, 'Could not save: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _export() async {
    await _capturePreview();
    if (!mounted) return;
    final savedId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ExportScreen(
          design: _c.design,
          initialSize: _size,
          historyId: _historyId,
          categoryId: _categoryId,
          categoryName: _categoryName,
          title: _title,
        ),
      ),
    );
    if (savedId != null && savedId.isNotEmpty && mounted) {
      setState(() => _historyId = savedId);
    }
  }

  Widget _buildTextEditChrome() {
    return Container(
      color: const Color(0xFF1A1E27),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _textModeController,
                focusNode: _textModeFocusNode,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'Type here',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                ),
                onChanged: _syncTextLive,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _finishTextMode(removeIfEmpty: true),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => _finishTextMode(removeIfEmpty: true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(72, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToolbar() {
    return Container(
      color: const Color(0xFF1A1E27),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: 9,
            separatorBuilder: (_, _) => const SizedBox(width: 2),
            itemBuilder: (context, i) {
              switch (i) {
                case 0:
                  return EditorToolButton(
                    icon: CupertinoIcons.textformat,
                    label: 'Text',
                    active: _textEditMode,
                    onTap: _startTextMode,
                  );
                case 1:
                  return EditorToolButton(
                    icon: CupertinoIcons.photo_on_rectangle,
                    label: 'BG',
                    onTap: _changeBackground,
                  );
                case 2:
                  return EditorToolButton(
                    icon: CupertinoIcons.sparkles,
                    label: 'Sticker',
                    onTap: _openStickerPicker,
                  );
                case 3:
                  return EditorToolButton(
                    icon: CupertinoIcons.star,
                    label: 'Icon',
                    onTap: _addIcon,
                  );
                case 4:
                  return EditorToolButton(
                    icon: CupertinoIcons.photo,
                    label: 'Photo',
                    onTap: () => _pickImage(role: LayerRole.none),
                  );
                case 5:
                  return EditorToolButton(
                    icon: CupertinoIcons.briefcase,
                    label: 'Logo',
                    onTap: () => _pickImage(role: LayerRole.logo),
                  );
                case 6:
                  return EditorToolButton(
                    icon: CupertinoIcons.square_on_circle,
                    label: 'Shape',
                    onTap: _addShape,
                  );
                case 7:
                  return EditorToolButton(
                    icon: CupertinoIcons.paintbrush,
                    label: 'Overlay',
                    onTap: _editOverlay,
                  );
                case 8:
                  return EditorToolButton(
                    icon: CupertinoIcons.rectangle_expand_vertical,
                    label: 'Size',
                    onTap: _chooseSize,
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar() {
    final layer = _selected;
    if (layer == null) return const SizedBox.shrink();

    final isText = layer.type == LayerType.text;
    final isImage = layer.type == LayerType.image;

    final tools = <Widget>[
      EditorToolButton(
        icon: CupertinoIcons.checkmark_alt,
        label: 'Done',
        active: true,
        onTap: _clearSelection,
      ),
    ];

    if (isText) {
      tools.addAll([
        EditorToolButton(icon: CupertinoIcons.pencil, label: 'Edit', onTap: _enterTextEdit),
        EditorToolButton(
          icon: CupertinoIcons.textformat_size,
          label: 'Font',
          active: _showStylePanel,
          onTap: () => setState(() => _showStylePanel = !_showStylePanel),
        ),
        EditorToolButton(icon: CupertinoIcons.paintbrush, label: 'Color', onTap: _openTextColorSheet),
        EditorToolButton(icon: CupertinoIcons.textformat_123, label: 'Size', onTap: _openFontSizeSheet),
        EditorToolButton(
          icon: CupertinoIcons.bold,
          label: 'Bold',
          active: layer.bold,
          onTap: _c.toggleBold,
        ),
        EditorToolButton(
          icon: CupertinoIcons.italic,
          label: 'Italic',
          active: layer.italic,
          onTap: _c.toggleItalic,
        ),
        EditorToolButton(
          icon: CupertinoIcons.text_alignleft,
          label: 'Left',
          active: layer.align == TextAlign.left,
          onTap: () => _c.setAlign(TextAlign.left),
        ),
        EditorToolButton(
          icon: CupertinoIcons.text_aligncenter,
          label: 'Center',
          active: layer.align == TextAlign.center,
          onTap: () => _c.setAlign(TextAlign.center),
        ),
        EditorToolButton(
          icon: CupertinoIcons.text_alignright,
          label: 'Right',
          active: layer.align == TextAlign.right,
          onTap: () => _c.setAlign(TextAlign.right),
        ),
      ]);
    } else if (isImage) {
      tools.add(
        EditorToolButton(
          icon: CupertinoIcons.arrow_2_squarepath,
          label: 'Replace',
          onTap: _replaceSelectedImage,
        ),
      );
    }

    if (!isImage && !isText) {
      tools.add(
        EditorToolButton(icon: CupertinoIcons.paintbrush, label: 'Color', onTap: _openFillColorSheet),
      );
    }

    tools.addAll([
      EditorToolButton(icon: CupertinoIcons.doc_on_doc, label: 'Copy', onTap: _c.duplicateSelected),
      EditorToolButton(icon: CupertinoIcons.arrow_up, label: 'Front', onTap: _c.bringToFront),
      EditorToolButton(icon: CupertinoIcons.arrow_down, label: 'Back', onTap: _c.sendToBack),
      EditorToolButton(
        icon: CupertinoIcons.delete,
        label: 'Delete',
        accentColor: AppColors.danger,
        onTap: () {
          _c.deleteSelected();
          setState(() => _showStylePanel = false);
        },
      ),
    ]);

    return Container(
      color: const Color(0xFF1A1E27),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: tools.length,
            separatorBuilder: (_, _) => const SizedBox(width: 2),
            itemBuilder: (context, i) => tools[i],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomChrome() {
    if (_textEditMode) return _buildTextEditChrome();
    if (_selected != null) return _buildSelectionToolbar();
    return _buildMainToolbar();
  }

  @override
  Widget build(BuildContext context) {
    if (_openFailed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not open this poster.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading || _controller == null) {
      return const Scaffold(body: LoadingView(label: 'Preparing your poster…'));
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final selected = _selected;
        final showStylePanel = _showStylePanel && selected != null && selected.type == LayerType.text;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1E27),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1E27),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Editor', style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              _appBarIcon(
                icon: CupertinoIcons.arrow_uturn_left,
                tooltip: 'Undo',
                onPressed: _c.canUndo ? _c.undo : null,
              ),
              _appBarIcon(
                icon: CupertinoIcons.arrow_uturn_right,
                tooltip: 'Redo',
                onPressed: _c.canRedo ? _c.redo : null,
              ),
              _appBarIcon(
                icon: CupertinoIcons.arrow_counterclockwise,
                tooltip: 'Reset',
                onPressed: _resetDesign,
              ),
              _appBarIcon(
                icon: CupertinoIcons.bookmark,
                tooltip: 'Save to History',
                onPressed: _saving ? null : _saveToHistory,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton(
                  onPressed: _export,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Export • ${_size.label.split(' ').first}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const BannerAdWidget(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: EditorCanvas(
                    controller: _c,
                    boundaryKey: _boundaryKey,
                    onTextLayerTap: _enterTextEdit,
                    onEmptyTap: () {
                      _finishTextMode(removeIfEmpty: true);
                      setState(() => _showStylePanel = false);
                    },
                  ),
                ),
              ),
              if (showStylePanel)
                EditorStylePanel(controller: _c, layer: selected),
              _buildBottomChrome(),
            ],
          ),
        );
      },
    );
  }
}

class _PickItem {
  final String value;
  final String label;
  final IconData icon;
  const _PickItem(this.value, this.label, this.icon);
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickItem> items;
  final ValueChanged<String> onSelected;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return EditorSheetScaffold(
      title: title,
      maxHeightFraction: 0.45,
      onDone: () => Navigator.pop(context),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(item.value),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: AppColors.primary),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
