import 'package:flutter/material.dart';

/// Category Slider Widget for Community Page
/// Horizontally scrollable category selection with icons
class CategorySlider extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<CategoryItem> categories;

  const CategorySlider({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categories,
  }) : super(key: key);

  @override
  State<CategorySlider> createState() => _CategorySliderState();
}

class _CategorySliderState extends State<CategorySlider> {
  @override
  Widget build(BuildContext context) {
    const Color deepEmerald = Color(0xFF1B5E47);
    const Color brushGold = Color(0xFFD4A574);
    const Color softCream = Color(0xFFFAF7F2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: widget.categories.map((category) {
          final isSelected = widget.selectedCategory == category.id;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => widget.onCategoryChanged(category.id),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Icon Container
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? deepEmerald.withOpacity(0.15)
                          : softCream,
                      border: isSelected
                          ? Border.all(color: brushGold, width: 2.5)
                          : Border.all(color: Colors.grey[200]!, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: brushGold.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      category.icon,
                      size: 32,
                      color: isSelected ? brushGold : deepEmerald,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category Label
                  SizedBox(
                    width: 70,
                    child: Text(
                      category.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? deepEmerald : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Category Item Model
class CategoryItem {
  final String id;
  final String label;
  final IconData icon;

  CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
