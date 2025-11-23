import 'package:flutter/material.dart';

class CategoryIconOption {
  final String id;
  final IconData icon;
  final Color bgColor;

  const CategoryIconOption({
    required this.id,
    required this.icon,
    required this.bgColor,
  });
}

const List<CategoryIconOption> kCategoryIconOptions = [
  CategoryIconOption(
    id: 'transport',
    icon: Icons.directions_car,
    bgColor: Colors.purple,
  ),
  CategoryIconOption(
    id: 'clothing',
    icon: Icons.checkroom,
    bgColor: Colors.orange,
  ),
  CategoryIconOption(
    id: 'food',
    icon: Icons.restaurant,
    bgColor: Colors.red,
  ),
  CategoryIconOption(
    id: 'home',
    icon: Icons.home,
    bgColor: Colors.pink,
  ),
  CategoryIconOption(
    id: 'shopping',
    icon: Icons.shopping_cart,
    bgColor: Colors.blue,
  ),
  CategoryIconOption(
    id: 'bills',
    icon: Icons.receipt_long,
    bgColor: Colors.deepOrange,
  ),
  CategoryIconOption(
    id: 'health',
    icon: Icons.healing,
    bgColor: Colors.green,
  ),
  CategoryIconOption(
    id: 'entertainment',
    icon: Icons.movie,
    bgColor: Colors.indigo,
  ),
  CategoryIconOption(
    id: 'sports',
    icon: Icons.sports_tennis,
    bgColor: Colors.teal,
  ),
  CategoryIconOption(
    id: 'technology',
    icon: Icons.phone_android,
    bgColor: Colors.lime,
  ),
];

CategoryIconOption getCategoryIconOptionById(String? id) {
  if (id == null) return kCategoryIconOptions.first;

  return kCategoryIconOptions.firstWhere(
    (option) => option.id == id,
    orElse: () => kCategoryIconOptions.first,
  );
}

CategoryIconOption getCategoryIconOptionFromData(Map<String, dynamic> data) {
  final iconId = data['iconId'] as String?;
  final iconIndex = (data['iconIndex'] as num?)?.toInt();

  if (iconId != null) {
    return getCategoryIconOptionById(iconId);
  }

  if (iconIndex != null &&
      iconIndex >= 0 &&
      iconIndex < kCategoryIconOptions.length) {
    return kCategoryIconOptions[iconIndex];
  }

  return kCategoryIconOptions.first;
}

Color getCategoryIconBgColor(Map<String, dynamic> data) {
  final colorValue = data['iconColor'];
  if (colorValue is int) {
    return Color(colorValue);
  }

  return getCategoryIconOptionFromData(data).bgColor;
}
