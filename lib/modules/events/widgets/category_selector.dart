// lib/modules/events/widgets/category_selector.dart
import 'package:flutter/material.dart';
import '../../../utils/categories.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategorySelector({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: 'Catégorie',
        border: OutlineInputBorder(),
      ),
      items: EventCategories.categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Text(EventCategories.categoryIcons[category] ?? '📅'),
              SizedBox(width: 8),
              Text(category),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onCategoryChanged(value);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner une catégorie';
        }
        return null;
      },
    );
  }
}