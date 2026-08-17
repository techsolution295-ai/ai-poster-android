import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/sticker_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_skeleton.dart';
import 'editor_sheet_scaffold.dart';

/// Bottom sheet for picking a decorative sticker from the CDN library.
class StickerPickerSheet extends StatefulWidget {
  const StickerPickerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StickerPickerSheet(),
    );
  }

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  final _service = StickerService.instance;

  List<StickerCategory> _categories = const [];
  bool _loading = true;
  String? _error;
  int _categoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await _service.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _pick(String url) => Navigator.pop(context, url);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: EditorSheetScaffold(
        title: 'Stickers',
        maxHeightFraction: 1,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: LoadingView(label: 'Loading stickers…'),
      );
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_categories.isEmpty) {
      return const EmptyState(
        title: 'No stickers found',
        message: 'Please try again later.',
      );
    }

    if (_categoryIndex >= _categories.length) _categoryIndex = 0;
    final category = _categories[_categoryIndex];
    final thumbs = _service.thumbnailsFor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = i == _categoryIndex;
              return ChoiceChip(
                label: Text(cat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: selected,
                onSelected: (_) => setState(() => _categoryIndex = i),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: thumbs.length,
            itemBuilder: (context, i) {
              final url = thumbs[i];
              return Material(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _pick(url),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
