import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/color_utils.dart';
import '../../models/category_model.dart';
import '../../models/design_model.dart';
import '../../models/template_model.dart';
import '../../providers/app_state.dart';
import '../../services/home_bootstrap.dart';
import '../../services/template_generator_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/template_card.dart';
import '../editor/poster_editor_screen.dart';
import '../ai/ai_prompt_screen.dart';

/// Home tab: a gradient header, a horizontal row of categories at the top, and
/// the auto-generated templates for the selected category below.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _gen = TemplateGeneratorService.instance;

  List<CategoryModel> _categories = [];
  int _selected = 0;

  List<TemplateModel> _templates = [];
  List<PosterDesign> _previews = [];

  bool _loadingCategories = true;
  bool _loadingTemplates = false;
  bool _error = false;

  /// Aspect ratio used for the poster previews (matches the default export size
  /// so what you see in the grid is what you edit/export).
  double _previewAspect = ExportSize.posterPortrait.aspectRatio;

  @override
  void initState() {
    super.initState();
    final warmed = HomeBootstrap.take();
    if (warmed != null) {
      _categories = warmed.categories;
      _templates = warmed.templates;
      _previews = warmed.previews;
      _previewAspect = warmed.previewAspect;
      _selected = warmed.selected;
      _loadingCategories = false;
      _loadingTemplates = false;
    } else {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await _gen.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loadingCategories = false;
    });
    if (cats.isNotEmpty) _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    if (_categories.isEmpty) return;
    setState(() {
      _loadingTemplates = true;
      _error = false;
    });
    try {
      final appState = context.read<AppState>();
      final brand = appState.brand;
      final aspect = appState.defaultSize.aspectRatio;
      final category = _categories[_selected];
      final templates = await _gen.generateTemplates(category.id);
      final previews = await Future.wait(
        templates.map((t) => _gen.buildPreviewDesign(t, brand: brand, aspectRatio: aspect)),
      );
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _previews = previews;
        _previewAspect = aspect;
        _loadingTemplates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTemplates = false;
        _error = true;
      });
    }
  }


  void _selectCategory(int i) {
    if (i == _selected) return;
    setState(() {
      _selected = i;
      _templates = [];
      _previews = [];
    });
    _loadTemplates();
  }

  void _openTemplate(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosterEditorScreen(
          template: _templates[index],
          category: _categories[_selected],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(),
          _categoryRow(),
          Expanded(child: _templatesArea()),
        ],
      ),
    );
  }

  // ---- Header --------------------------------------------------------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiPromptScreen()),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            // Match the actual banner ratio so it displays fully without crop.
            aspectRatio: 886 / 322,
            child: Image.asset(AppConstants.homeBannerAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // ---- Category row --------------------------------------------------------

  Widget _categoryRow() {
    if (_loadingCategories) {
      return const SizedBox(
        height: 104,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return SizedBox(
      height: 122,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chipWidth = (constraints.maxWidth * 0.18).clamp(70.0, 82.0);
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _categoryChip(_categories[i], i, chipWidth: chipWidth),
          );
        },
      ),
    );
  }

  Widget _categoryChip(CategoryModel c, int i, {required double chipWidth}) {
    final selected = i == _selected;
    final color = ColorUtils.fromHex(c.colorHex, fallback: AppColors.primary);
    return GestureDetector(
      onTap: () => _selectCategory(i),
      child: SizedBox(
        width: chipWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [color, color.withValues(alpha: 0.7)]
                      : [Colors.white, Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.transparent : AppColors.divider,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.34),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ]
                    : null,
              ),
              child: Icon(
                _categoryIcon(c),
                color: selected ? Colors.white : color,
                size: 25,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _shortName(c.name),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.darkText : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A clean, single-word label for the category chip (full name is still used
  /// for the section header below).
  String _shortName(String name) {
    const overrides = {
      'Umrah Posters': 'Umrah',
      'Business Flyers': 'Business',
      'College Admission': 'College',
      'Travel Thumbnails': 'Travel',
      'Sale / Offer Posters': 'Sale',
      'Announcements': 'Notice',
      'Social Media Posts': 'Social',
    };
    return overrides[name] ?? name.split(' ').first;
  }

  /// Professional Cupertino icons for the category row.
  IconData _categoryIcon(CategoryModel c) {
    switch (c.id) {
      case 'umrah':
        return CupertinoIcons.moon_stars_fill;
      case 'business':
        return CupertinoIcons.briefcase_fill;
      case 'college':
        return CupertinoIcons.book_fill;
      case 'travel':
        return CupertinoIcons.airplane;
      case 'sale':
        return CupertinoIcons.tag_fill;
      case 'announcements':
        return CupertinoIcons.bell_fill;
      case 'social':
        return CupertinoIcons.chat_bubble_2_fill;
      default:
        return CupertinoIcons.square_grid_2x2_fill;
    }
  }

  // ---- Templates area ------------------------------------------------------

  Widget _templatesArea() {
    if (_loadingCategories) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _categories.isEmpty
                      ? 'Trending Templates'
                      : 'Trending ${_shortName(_categories[_selected].name)} Templates',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (!_loadingTemplates)
                TextButton.icon(
                  onPressed: _loadTemplates,
                  iconAlignment: IconAlignment.start,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Refresh',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        Expanded(child: _templatesGrid()),
      ],
    );
  }

  Widget _templatesGrid() {
    if (_loadingTemplates) return const TemplateGridSkeleton(itemCount: 8);

    if (_error) {
      return ErrorState(
        message: 'Could not load templates. Check your connection.',
        onRetry: _loadTemplates,
      );
    }

    if (_previews.isEmpty) {
      return EmptyState(
        icon: Icons.image_search,
        title: 'No templates yet',
        message: 'Connect to the internet to generate fresh designs, then tap Refresh.',
        action: OutlinedButton.icon(
          onPressed: _loadTemplates,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: _previewAspect,
        ),
        itemCount: _previews.length,
        itemBuilder: (context, i) => TemplateCard(
          design: _previews[i],
          onTap: () => _openTemplate(i),
        ),
      ),
    );
  }
}
