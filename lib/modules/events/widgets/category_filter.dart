// lib/modules/events/widgets/category_filter.dart
import 'package:flutter/material.dart';
import '../../../../utils/categories.dart';

class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategoryFilter({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildCategoryChip('Toutes'),
          ...EventCategories.categories.map(_buildCategoryChip),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = category == selectedCategory;

    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != 'Toutes')
              Text(EventCategories.categoryIcons[category] ?? '📅'),
            SizedBox(width: 4),
            Text(category),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          onCategoryChanged(category);
        },
        backgroundColor: isSelected ? Color(0xFFCE1126).withOpacity(0.1) : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Color(0xFFCE1126) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Color(0xFFCE1126),
      ),
    );
  }
}