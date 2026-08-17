import '../core/constants/app_sizes.dart';
import '../models/category_model.dart';
import '../models/design_model.dart';
import '../models/template_model.dart';
import '../providers/app_state.dart';
import 'template_generator_service.dart';

/// Preloads the first home screen payload during splash so Home opens ready
/// instead of sitting on an empty white frame for a few seconds.
class HomeBootstrap {
  HomeBootstrap._();

  static List<CategoryModel>? categories;
  static List<TemplateModel>? templates;
  static List<PosterDesign>? previews;
  static double? previewAspect;
  static int selectedCategory = 0;

  static bool get hasData =>
      categories != null &&
      categories!.isNotEmpty &&
      templates != null &&
      previews != null;

  static Future<void> preload(AppState appState) async {
    final gen = TemplateGeneratorService.instance;
    final cats = await gen.getCategories();
    if (cats.isEmpty) {
      categories = cats;
      templates = const [];
      previews = const [];
      return;
    }

    final aspect = appState.defaultSize.aspectRatio;
    final templatesList = await gen.generateTemplates(cats.first.id);
    final previewList = await Future.wait(
      templatesList.map(
        (t) => gen.buildPreviewDesign(
          t,
          brand: appState.brand,
          aspectRatio: aspect,
        ),
      ),
    );

    categories = cats;
    templates = templatesList;
    previews = previewList;
    previewAspect = aspect;
    selectedCategory = 0;
  }

  /// Hands off cached data to HomeScreen (one-shot).
  static ({
    List<CategoryModel> categories,
    List<TemplateModel> templates,
    List<PosterDesign> previews,
    double previewAspect,
    int selected,
  })? take() {
    if (!hasData) return null;
    final result = (
      categories: List<CategoryModel>.from(categories!),
      templates: List<TemplateModel>.from(templates!),
      previews: List<PosterDesign>.from(previews!),
      previewAspect: previewAspect!,
      selected: selectedCategory,
    );
    categories = null;
    templates = null;
    previews = null;
    previewAspect = null;
    selectedCategory = 0;
    return result;
  }
}
