import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/pexels_service.dart';
import '../../services/pixabay_service.dart';
import '../../services/stock_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

/// Lets the user search free stock photos and pick a new background. Returns the
/// chosen [StockImage] via `Navigator.pop`. Pixabay results are cached locally
/// by the caller before use (no permanent hotlinking).
class BackgroundChangeScreen extends StatefulWidget {
  final String initialQuery;
  final String categoryId;

  const BackgroundChangeScreen({
    super.key,
    this.initialQuery = '',
    this.categoryId = '',
  });

  @override
  State<BackgroundChangeScreen> createState() => _BackgroundChangeScreenState();
}

class _BackgroundChangeScreenState extends State<BackgroundChangeScreen> {
  late final TextEditingController _search =
      TextEditingController(text: widget.initialQuery);
  List<StockImage> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run(widget.initialQuery.isEmpty ? 'abstract background' : widget.initialQuery);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(String query) async {
    setState(() => _loading = true);
    final results = <StockImage>[];
    results.addAll(await PexelsService.instance.search(query, perPage: 24));
    if (results.length < 24) {
      results.addAll(await PixabayService.instance.search(query, perPage: 24));
    }
    if (results.isEmpty) {
      // Key-less demo fallback (Lorem Picsum) so the picker is never empty online.
      final seed = query.hashCode.abs();
      results.addAll(List.generate(
        18,
        (i) => StockImage(
          url: 'https://picsum.photos/seed/$seed$i/1080/1080',
          previewUrl: 'https://picsum.photos/seed/$seed$i/400/400',
          sourceName: 'Lorem Picsum (demo)',
          sourcePageUrl: 'https://picsum.photos',
          licenseNote: 'Demo placeholder image.',
        ),
      ));
    }
    if (!mounted) return;
    setState(() {
      _images = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change background')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              decoration: InputDecoration(
                hintText: 'Search photos (e.g. mosque, sale, mountain)…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _run(_search.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const TemplateGridSkeleton(itemCount: 9)
                : _images.isEmpty
                    ? ErrorState(
                        message: 'No images found. Check your connection and try again.',
                        onRetry: () => _run(_search.text),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, i) {
                          final img = _images[i];
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, img),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: img.previewUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    const ColoredBox(color: AppColors.divider),
                                errorWidget: (_, _, _) => const ColoredBox(
                                  color: AppColors.divider,
                                  child: Icon(Icons.broken_image, color: AppColors.muted),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
