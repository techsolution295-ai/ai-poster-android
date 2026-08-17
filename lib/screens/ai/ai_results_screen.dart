import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../models/category_model.dart';
import '../../models/design_model.dart';
import '../../models/template_model.dart';
import '../../services/ai_poster_api_service.dart';
import '../../providers/app_state.dart';
import '../../services/prompt_ai_service.dart';
import '../../services/template_generator_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/template_card.dart';
import '../editor/poster_editor_screen.dart';

/// Shows generated templates for a user prompt in a separate screen.
class AiResultsScreen extends StatefulWidget {
  final String prompt;
  const AiResultsScreen({super.key, required this.prompt});

  @override
  State<AiResultsScreen> createState() => _AiResultsScreenState();
}

class _AiResultsScreenState extends State<AiResultsScreen> {
  final _gen = TemplateGeneratorService.instance;

  bool _loading = true;
  bool _error = false;
  PromptDraft? _draft;
  CategoryModel? _category;
  List<TemplateModel> _templates = [];
  List<PosterDesign> _previews = [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final app = context.read<AppState>();
      final draft = await PromptAiService.instance.parse(widget.prompt);
      final categories = await _gen.getCategories();
      if (!mounted) return;
      final category = categories.firstWhere(
        (c) => c.id == draft.categoryId,
        orElse: () => categories.first,
      );

      // 1) Try AI image generation API first (prompt -> images).
      final aiImages = await AiPosterApiService.instance.generatePosterImages(
        prompt: widget.prompt,
        count: 12,
        width: 1080,
        height: 1350,
      );

      // 2) Turn those images into editable templates via local layouts.
      //    If API is slow/unavailable, gracefully fall back to existing
      //    Pexels/Pixabay generator flow.
      final cleanTexts = _cleanTemplateTexts(
        prompt: widget.prompt,
        draft: draft,
        phone: app.brand.phone,
      );

      final templates = aiImages.isNotEmpty
          ? await _gen.buildTemplatesFromStockImages(
              category.id,
              aiImages,
              textOverrides: cleanTexts,
            )
          : await _gen.generateTemplates(
              category.id,
              keywordOverrides: draft.keywords,
              textOverrides: cleanTexts,
            );
      final previews = await Future.wait(
        templates.map((t) => _gen.buildPreviewDesign(
              t,
              brand: app.brand,
              aspectRatio: app.defaultSize.aspectRatio,
            )),
      );
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _category = category;
        _templates = templates;
        _previews = previews;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _openTemplate(int index) {
    if (_category == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosterEditorScreen(
          template: _templates[index],
          category: _category,
        ),
      ),
    );
  }

  /// Converts a long user prompt into concise, poster-friendly copy.
  /// The prompt is treated as design intent, not as literal text content.
  Map<String, String> _cleanTemplateTexts({
    required String prompt,
    required PromptDraft draft,
    required String phone,
  }) {
    final title = _smartTitle(draft.categoryId, draft.title);
    final subtitle = _smartSubtitle(draft.categoryId, draft.subtitle);
    final details = _smartDetails(draft.categoryId, draft.details);
    final price = _extractOffer(prompt, fallback: draft.price);
    return {
      'title': title,
      'subtitle': subtitle,
      'details': details,
      'price': price,
      if (phone.isNotEmpty) 'contact': phone,
    };
  }

  String _smartTitle(String categoryId, String raw) {
    final cleaned = _sanitize(raw, max: 30);
    if (cleaned.isNotEmpty && cleaned.split(' ').length <= 5) return cleaned;
    switch (categoryId) {
      case 'umrah':
        return 'Umrah Package 2026';
      case 'business':
        return 'Grow Your Business';
      case 'college':
        return 'Admissions Open';
      case 'travel':
        return 'Adventure Awaits';
      case 'sale':
        return 'Mega Sale';
      case 'announcements':
        return 'Important Notice';
      case 'social':
        return 'New Post';
      default:
        return 'Special Offer';
    }
  }

  String _smartSubtitle(String categoryId, String raw) {
    final cleaned = _sanitize(raw, max: 38);
    if (cleaned.isNotEmpty && cleaned.split(' ').length <= 8) return cleaned;
    switch (categoryId) {
      case 'umrah':
        return 'A spiritual journey like no other';
      case 'business':
        return 'Professional services you can trust';
      case 'college':
        return 'Limited seats • Apply today';
      case 'travel':
        return 'Explore stunning destinations';
      case 'sale':
        return 'Limited time deals available now';
      case 'announcements':
        return 'Please read and share';
      case 'social':
        return 'Fresh content for your audience';
      default:
        return 'Designed for your campaign';
    }
  }

  String _smartDetails(String categoryId, String raw) {
    final cleaned = _sanitize(raw, max: 54);
    if (cleaned.isNotEmpty && cleaned.split(' ').length <= 11) return cleaned;
    switch (categoryId) {
      case 'umrah':
        return 'Flights • Hotels • Visa • Transport';
      case 'business':
        return 'Call now for details';
      case 'college':
        return 'Scholarships available';
      case 'travel':
        return 'Book now and save';
      case 'sale':
        return 'Shop now while stock lasts';
      case 'announcements':
        return 'Stay updated with latest info';
      case 'social':
        return 'Like • Share • Follow';
      default:
        return 'Contact us for details';
    }
  }

  String _extractOffer(String prompt, {required String fallback}) {
    final pct = RegExp(r'(\d{1,2}\s?%[\s\-]?(off|discount)?)', caseSensitive: false)
        .firstMatch(prompt);
    if (pct != null) return pct.group(1)!.toUpperCase();
    final money = RegExp(r'(\$|rs\.?|pkr)\s?\d+', caseSensitive: false).firstMatch(prompt);
    if (money != null) return 'From ${money.group(0)!.toUpperCase()}';
    return _sanitize(fallback, max: 16);
  }

  String _sanitize(String raw, {required int max}) {
    var t = raw.trim();
    // Remove instruction-like leading verbs so content reads like ad copy.
    t = t.replaceFirst(
      RegExp(
          r'^(make|create|design|generate|build|write)\s+(a|an)?\s*(poster|flyer|thumbnail)?\s*(for)?\s*',
          caseSensitive: false),
      '',
    );
    t = t.replaceAll(RegExp(r'[\n\r]+'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    if (t.length > max) t = '${t.substring(0, max - 1)}…';
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated Results')),
      body: _loading
          ? const TemplateGridSkeleton(itemCount: 8)
          : _error
              ? ErrorState(message: 'Generation failed. Try another prompt.', onRetry: _run)
              : _previews.isEmpty
                  ? EmptyState(
                      title: 'No templates generated',
                      message: 'Try a clearer prompt with category details.',
                      action: OutlinedButton.icon(
                        onPressed: _run,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    )
                  : Column(
                      children: [
                        if (_draft != null && _category != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_category!.name} • "${_draft!.title}"',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                          ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _previews.length,
                            itemBuilder: (context, i) => TemplateCard(
                              design: _previews[i],
                              onTap: () => _openTemplate(i),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

