import 'package:flutter/material.dart';

class CategorySlider extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<CategoryItem> categories;
  const CategorySlider({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categories,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
    child: Row(
      children: categories
          .map(
            (category) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(category.label),
                selected: selectedCategory == category.id,
                onSelected: (_) => onCategoryChanged(category.id),
                avatar: Icon(category.icon, size: 18),
                visualDensity: VisualDensity.standard,
              ),
            ),
          )
          .toList(),
    ),
  );
}

class CategoryItem {
  final String id;
  final String label;
  final IconData icon;
  CategoryItem({required this.id, required this.label, required this.icon});
}
