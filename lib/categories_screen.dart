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

  final List<IconData> _categoryIcons = const [
    Icons.restaurant,
    Icons.directions_car,
    Icons.home_rounded,
    Icons.shopping_bag,
    Icons.school,
    Icons.favorite,
    Icons.flight_takeoff,
    Icons.savings,
    Icons.sports_esports,
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
                          const SizedBox(height: 24),
                          _buildAddCategoryButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddCategoryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeService.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text(
          "ADD NEW CATEGORY",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
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

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController nameController = TextEditingController();
    int selectedIconIndex = 0;
    String selectedType = 'EXPENSE';

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: _themeService.cardBg,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Add new category',
                        style: TextStyle(
                          color: _themeService.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Type:',
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final type in ['INCOME', 'EXPENSE'])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      selectedType == type ? _themeService.primaryBlue : _themeService.cardBg,
                                  foregroundColor:
                                      selectedType == type ? Colors.white : _themeService.textSub,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _themeService.textSub.withValues(alpha: 0.25),
                                    ),
                                  ),
                                ),
                                onPressed: () => setState(() => selectedType = type),
                                child: Text(
                                  type,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Name',
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Untitled',
                        filled: true,
                        fillColor: _themeService.cardBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.textSub.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _themeService.primaryBlue),
                        ),
                      ),
                      style: TextStyle(color: _themeService.textMain),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Icon',
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _themeService.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _themeService.textSub.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (int i = 0; i < _categoryIcons.length; i++)
                            GestureDetector(
                              onTap: () => setState(() => selectedIconIndex = i),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _categoryColors[i % _categoryColors.length]
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: selectedIconIndex == i
                                        ? _themeService.primaryBlue
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _categoryIcons[i],
                                  color: _categoryColors[i % _categoryColors.length],
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _themeService.textMain,
                              side: BorderSide(
                                color: _themeService.textSub.withValues(alpha: 0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _themeService.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final name = nameController.text.trim();
                              // TODO: Save new category to data store
                              debugPrint('Saving category: type=$selectedType, name=$name, iconIndex=$selectedIconIndex');
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'SAVE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
