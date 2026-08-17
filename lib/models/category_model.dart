/// A poster category, loaded from `assets/data/categories.json`.
class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.colorHex = '#FF6C2BD9',
    this.sortOrder = 0,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> m) {
    return CategoryModel(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      icon: m['icon']?.toString() ?? 'star',
      colorHex: m['color']?.toString() ?? '#FF6C2BD9',
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
