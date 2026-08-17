import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/utils/ui_helpers.dart';
import '../../engine/poster_canvas.dart';
import '../../models/design_model.dart';
import '../../providers/app_state.dart';
import '../../services/design_history_service.dart';
import '../../services/export_service.dart';
import '../../widgets/app_button.dart';

/// Final step: choose size + format, then save to gallery or print the poster.
class ExportScreen extends StatefulWidget {
  final PosterDesign design;
  final ExportSize initialSize;

  /// When set, saving updates this history entry instead of creating a new one.
  final String? historyId;
  final String categoryId;
  final String categoryName;
  final String title;

  const ExportScreen({
    super.key,
    required this.design,
    this.initialSize = ExportSize.instagramPost,
    this.historyId,
    this.categoryId = '',
    this.categoryName = '',
    this.title = '',
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _boundaryKey = GlobalKey();
  late ExportSize _size = widget.initialSize;
  ExportFormat _format = ExportFormat.png;
  bool _busy = false;
  String? _historyId;

  late PosterDesign _design;

  @override
  void initState() {
    super.initState();
    _design = PosterDesign.fromMap(widget.design.toMap());
    _design.aspectRatio = _size.aspectRatio;
    _historyId = widget.historyId;
  }

  void _setSize(ExportSize s) {
    setState(() {
      _size = s;
      _design.aspectRatio = s.aspectRatio;
    });
  }

  Future<Uint8List> _capture() async {
    final quality = context.read<AppState>().exportQuality;
    final width = ExportHelper.widthForQuality(quality, _size.dimensions.width);
    await WidgetsBinding.instance.endOfFrame;
    return ExportService.instance.capture(
      boundaryKey: _boundaryKey,
      targetWidth: width,
      format: _format,
    );
  }

  Future<void> _persistToHistory(Uint8List bytes) async {
    final saved = await DesignHistoryService.instance.savePoster(
      design: _design,
      id: _historyId,
      categoryId: widget.categoryId,
      categoryName: widget.categoryName,
      title: widget.title,
      previewBytes: bytes,
    );
    _historyId = saved.id;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();

      // Always keep a local history copy so My Designs stays in sync.
      await _persistToHistory(bytes);

      final granted = await PermissionHelper.ensureGallerySave();
      if (!granted) {
        if (mounted) {
          UiHelpers.showSnack(
            context,
            'Saved to History. Gallery permission is needed to save to Photos.',
          );
        }
        return;
      }

      final name = ExportHelper.fileName(prefix: 'poster', format: _format);
      final ok = await ExportService.instance.saveToGallery(bytes, fileName: name);
      if (mounted) {
        UiHelpers.showSnack(
          context,
          ok
              ? 'Saved to gallery and History'
              : 'Saved to History, but gallery save failed.',
          error: !ok,
        );
      }
    } catch (e) {
      if (mounted) UiHelpers.showSnack(context, 'Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      await _persistToHistory(bytes);
      final name = ExportHelper.fileName(prefix: 'poster', format: _format);
      await ExportService.instance
          .share(bytes, fileName: name, text: 'Made with Poster Maker');
    } catch (e) {
      if (mounted) UiHelpers.showSnack(context, 'Share failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      await _persistToHistory(bytes);
      final name = ExportHelper.fileName(prefix: 'poster', format: _format);
      await ExportService.instance.printPoster(bytes, fileName: name);
      if (mounted) {
        UiHelpers.showSnack(context, 'Also saved to History');
      }
    } catch (e) {
      if (mounted) UiHelpers.showSnack(context, 'Print failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_historyId);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: _busy ? null : _share,
            icon: const Icon(CupertinoIcons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFEDEFF3),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: PosterCanvas(design: _design),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Size', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final s in ExportSize.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(s.label),
                              selected: s == _size,
                              onSelected: (_) => _setSize(s),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Format', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('PNG'),
                        selected: _format == ExportFormat.png,
                        onSelected: (_) => setState(() => _format = ExportFormat.png),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('JPG'),
                        selected: _format == ExportFormat.jpg,
                        onSelected: (_) => setState(() => _format = ExportFormat.jpg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Save',
                          icon: Icons.download_rounded,
                          loading: _busy,
                          onPressed: _busy ? null : _save,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Print',
                          icon: Icons.print_rounded,
                          gradient: AppColors.premiumGradient,
                          loading: _busy,
                          onPressed: _busy ? null : _print,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
