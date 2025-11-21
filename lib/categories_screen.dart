import 'package:flutter/material.dart';
import 'package:smartspend/services/theme_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ThemeService _themeService = ThemeService();

  final List<String> _incomeCategories = [
    'Salary',
    'Awards',
    'Grants',
    'Rental',
    'Investments',
    'Refunds',
    'Gifts',
    'Interest',
  ];

  final List<String> _expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Bills',
    'Groceries',
    'Entertainment',
    'Shopping',
    'Healthcare',
    'Education',
    'Travel',
    'Utilities',
  ];

  final List<Color> _categoryColors = const [
    Color(0xFF64B6FF),
    Color(0xFF7BD6C8),
    Color(0xFFFFB870),
    Color(0xFF8E97FD),
    Color(0xFFFF8FA2),
    Color(0xFF6ED1FF),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_themeService.bgTop, _themeService.bgBottom],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: "Income categories",
                            categories: _incomeCategories,
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: "Expense categories",
                            categories: _expenseCategories,
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: FloatingActionButton.extended(
              backgroundColor: _themeService.primaryBlue,
              onPressed: () {
                // TODO: open Add Category page
              },
              label: const Text(
                "ADD NEW CATEGORY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required List<String> categories}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _themeService.textMain,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 1,
          color: _themeService.textSub.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (int i = 0; i < categories.length; i++)
              _buildCategoryRow(
                categories[i],
                _categoryColors[i % _categoryColors.length],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryRow(String categoryName, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _themeService.isDarkMode ? 0.2 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              categoryName,
              style: TextStyle(
                color: _themeService.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: _themeService.textSub),
            onPressed: () {
              // TODO: open category actions
            },
          ),
        ],
      ),
    );
  }
}
