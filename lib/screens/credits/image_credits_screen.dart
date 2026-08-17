import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/design_model.dart';
import '../../services/design_history_service.dart';
import '../../widgets/loading_skeleton.dart';

/// Shows attribution for the free assets used by the app: the image providers
/// (Pexels, Pixabay), Google Fonts, plus the specific photo sources referenced
/// by the user's saved designs.
class ImageCreditsScreen extends StatefulWidget {
  const ImageCreditsScreen({super.key});

  @override
  State<ImageCreditsScreen> createState() => _ImageCreditsScreenState();
}

class _ImageCreditsScreenState extends State<ImageCreditsScreen> {
  List<SavedDesign> _designs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final designs = await DesignHistoryService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _designs = designs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image credits')),
      body: _loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _providerCard(
                  'Pexels',
                  'Photos provided by Pexels, free to use under the Pexels License.',
                  'https://www.pexels.com',
                ),
                _providerCard(
                  'Pixabay',
                  'Images from Pixabay under the Pixabay Content License. '
                      'Selected images are cached on your device (no hotlinking).',
                  'https://pixabay.com',
                ),
                _providerCard(
                  'Google Fonts',
                  'Fonts provided by the google_fonts package, licensed under the '
                      'Open Font License.',
                  'https://fonts.google.com',
                ),
                const SizedBox(height: 12),
                const Text('Photos used in your designs',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                if (_usedSources.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Create and save designs to see the specific photo sources '
                      'and photographers credited here.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  ..._usedSources.map(_sourceTile),
              ],
            ),
    );
  }

  /// Unique (source, page, photographer) tuples from saved designs.
  List<PosterDesign> get _usedSources {
    final seen = <String>{};
    final result = <PosterDesign>[];
    for (final d in _designs) {
      final design = d.design;
      final key = '${design.sourceName}|${design.sourcePageUrl}|${design.photographerName}';
      if (design.sourceName != null &&
          design.sourceName!.isNotEmpty &&
          seen.add(key)) {
        result.add(design);
      }
    }
    return result;
  }

  Widget _providerCard(String title, String body, String url) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(body),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _open(url),
      ),
    );
  }

  Widget _sourceTile(PosterDesign d) {
    final photographer = d.photographerName;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.image, color: AppColors.secondary),
        title: Text(
          photographer != null && photographer.isNotEmpty
              ? '$photographer • ${d.sourceName}'
              : d.sourceName ?? 'Unknown',
        ),
        subtitle: Text(d.sourcePageUrl ?? ''),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _open(d.sourcePageUrl ?? ''),
      ),
    );
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
