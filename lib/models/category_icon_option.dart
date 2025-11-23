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

const Map<String, IconData> kCategoryIconMap = {
  'bills': Icons.receipt_long,
  'car': Icons.directions_car,
  'clothing': Icons.checkroom,
  'education': Icons.school,
  'electronics': Icons.devices,
  'entertainment': Icons.movie,
  'food': Icons.restaurant,
  'health': Icons.favorite,
  'home': Icons.home,
  'insurance': Icons.verified_user,
  'shopping': Icons.shopping_bag,
  'social': Icons.group,
  'sport': Icons.sports_soccer,
  'tax': Icons.receipt,
  'telephone': Icons.call,
  'awards': Icons.card_giftcard,
  'coupons': Icons.percent,
  'food_income': Icons.restaurant,
  'grants': Icons.volunteer_activism,
  'lottery': Icons.casino,
  'refunds': Icons.refresh,
  'rental': Icons.house,
  'salary': Icons.work,
  'sale': Icons.sell,
  // Legacy/compatibility keys
  'transport': Icons.directions_car,
  'sports': Icons.sports_tennis,
  'technology': Icons.phone_android,
  'food_dining': Icons.restaurant,
  'transportation': Icons.directions_bus_filled_outlined,
  'groceries': Icons.shopping_cart_outlined,
  'shopping_legacy': Icons.shopping_cart,
  'entertainment_legacy': Icons.movie_outlined,
  'investments': Icons.trending_up,
  'gifts': Icons.card_giftcard,
  'interest': Icons.savings,
};

const List<CategoryIconOption> kCategoryIconOptions = [
  CategoryIconOption(
    id: 'bills',
    icon: Icons.receipt_long,
    bgColor: Color(0xFF455A64),
  ),
  CategoryIconOption(
    id: 'car',
    icon: Icons.directions_car,
    bgColor: Color(0xFF6A1B9A),
  ),
  CategoryIconOption(
    id: 'clothing',
    icon: Icons.checkroom,
    bgColor: Color(0xFFFF9800),
  ),
  CategoryIconOption(
    id: 'education',
    icon: Icons.school,
    bgColor: Color(0xFF3949AB),
  ),
  CategoryIconOption(
    id: 'electronics',
    icon: Icons.devices,
    bgColor: Color(0xFF00897B),
  ),
  CategoryIconOption(
    id: 'entertainment',
    icon: Icons.movie,
    bgColor: Color(0xFFAB47BC),
  ),
  CategoryIconOption(
    id: 'food',
    icon: Icons.restaurant,
    bgColor: Color(0xFFE53935),
  ),
  CategoryIconOption(
    id: 'health',
    icon: Icons.favorite,
    bgColor: Color(0xFFD81B60),
  ),
  CategoryIconOption(
    id: 'home',
    icon: Icons.home,
    bgColor: Color(0xFF5D4037),
  ),
  CategoryIconOption(
    id: 'insurance',
    icon: Icons.verified_user,
    bgColor: Color(0xFFFFA726),
  ),
  CategoryIconOption(
    id: 'shopping',
    icon: Icons.shopping_bag,
    bgColor: Color(0xFF1976D2),
  ),
  CategoryIconOption(
    id: 'social',
    icon: Icons.group,
    bgColor: Color(0xFF2E7D32),
  ),
  CategoryIconOption(
    id: 'sport',
    icon: Icons.sports_soccer,
    bgColor: Color(0xFF43A047),
  ),
  CategoryIconOption(
    id: 'tax',
    icon: Icons.receipt,
    bgColor: Color(0xFF8D6E63),
  ),
  CategoryIconOption(
    id: 'telephone',
    icon: Icons.call,
    bgColor: Color(0xFF303F9F),
  ),
  CategoryIconOption(
    id: 'awards',
    icon: Icons.card_giftcard,
    bgColor: Color(0xFF1565C0),
  ),
  CategoryIconOption(
    id: 'coupons',
    icon: Icons.percent,
    bgColor: Color(0xFFE53935),
  ),
  CategoryIconOption(
    id: 'food_income',
    icon: Icons.restaurant,
    bgColor: Color(0xFFD32F2F),
  ),
  CategoryIconOption(
    id: 'grants',
    icon: Icons.volunteer_activism,
    bgColor: Color(0xFF00796B),
  ),
  CategoryIconOption(
    id: 'lottery',
    icon: Icons.casino,
    bgColor: Color(0xFFC62828),
  ),
  CategoryIconOption(
    id: 'refunds',
    icon: Icons.refresh,
    bgColor: Color(0xFF2E7D32),
  ),
  CategoryIconOption(
    id: 'rental',
    icon: Icons.house,
    bgColor: Color(0xFF6A1B9A),
  ),
  CategoryIconOption(
    id: 'salary',
    icon: Icons.work,
    bgColor: Color(0xFF283593),
  ),
  CategoryIconOption(
    id: 'sale',
    icon: Icons.sell,
    bgColor: Color(0xFF2E7D32),
  ),
  // Legacy options to support previously saved categories
  CategoryIconOption(
    id: 'transport',
    icon: Icons.directions_car,
    bgColor: Colors.purple,
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
  CategoryIconOption(
    id: 'food_dining',
    icon: Icons.restaurant,
    bgColor: Color(0xFF2979FF),
  ),
  CategoryIconOption(
    id: 'transportation',
    icon: Icons.directions_bus_filled_outlined,
    bgColor: Color(0xFF455A64),
  ),
  CategoryIconOption(
    id: 'groceries',
    icon: Icons.shopping_cart_outlined,
    bgColor: Color(0xFFFF7043),
  ),
  CategoryIconOption(
    id: 'shopping_legacy',
    icon: Icons.shopping_cart,
    bgColor: Colors.blue,
  ),
  CategoryIconOption(
    id: 'entertainment_legacy',
    icon: Icons.movie_outlined,
    bgColor: Color(0xFFE53935),
  ),
  CategoryIconOption(
    id: 'investments',
    icon: Icons.trending_up,
    bgColor: Color(0xFFF9A825),
  ),
  CategoryIconOption(
    id: 'gifts',
    icon: Icons.card_giftcard,
    bgColor: Color(0xFFD81B60),
  ),
  CategoryIconOption(
    id: 'interest',
    icon: Icons.savings,
    bgColor: Color(0xFF5D4037),
  ),
];

CategoryIconOption getCategoryIconOptionById(String? id) {
  if (id == null) return kCategoryIconOptions.first;

  return kCategoryIconOptions.firstWhere(
    (option) => option.id == id,
    orElse: () {
      final iconData = kCategoryIconMap[id];
      if (iconData != null) {
        return CategoryIconOption(
          id: id,
          icon: iconData,
          bgColor: kCategoryIconOptions.first.bgColor,
        );
      }

      return kCategoryIconOptions.first;
    },
  );
}

CategoryIconOption getCategoryIconOptionFromData(Map<String, dynamic> data) {
  final iconId = (data['iconId'] as String?) ?? data['icon'] as String?;
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
  final colorValue = data['iconColor'] ?? data['color'];
  if (colorValue is int) {
    return Color(colorValue);
  }

  return getCategoryIconOptionFromData(data).bgColor;
}
