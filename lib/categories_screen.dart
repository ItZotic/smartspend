import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartspend/models/category_icon_option.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/services/theme_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DefaultCategory {
  final String name;
  final String type; // 'income' or 'expense'
  final IconData icon;
  final Color color;

  const DefaultCategory({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });
}

const List<DefaultCategory> kDefaultIncomeCategories = [
  DefaultCategory(
    name: 'Awards',
    type: 'income',
    icon: Icons.card_giftcard,
    color: Color(0xFF1565C0),
  ),
  DefaultCategory(
    name: 'Coupons',
    type: 'income',
    icon: Icons.percent,
    color: Color(0xFFE53935),
  ),
  DefaultCategory(
    name: 'Food & Dining',
    type: 'income',
    icon: Icons.restaurant,
    color: Color(0xFFD32F2F),
  ),
  DefaultCategory(
    name: 'Grants',
    type: 'income',
    icon: Icons.volunteer_activism,
    color: Color(0xFF00796B),
  ),
  DefaultCategory(
    name: 'Lottery',
    type: 'income',
    icon: Icons.casino,
    color: Color(0xFFC62828),
  ),
  DefaultCategory(
    name: 'Refunds',
    type: 'income',
    icon: Icons.refresh,
    color: Color(0xFF2E7D32),
  ),
  DefaultCategory(
    name: 'Rental',
    type: 'income',
    icon: Icons.house,
    color: Color(0xFF6A1B9A),
  ),
  DefaultCategory(
    name: 'Salary',
    type: 'income',
    icon: Icons.work,
    color: Color(0xFF283593),
  ),
  DefaultCategory(
    name: 'Sale',
    type: 'income',
    icon: Icons.sell,
    color: Color(0xFF2E7D32),
  ),
];

const List<DefaultCategory> kDefaultExpenseCategories = [
  DefaultCategory(
    name: 'Bills',
    type: 'expense',
    icon: Icons.receipt_long,
    color: Color(0xFF455A64),
  ),
  DefaultCategory(
    name: 'Car',
    type: 'expense',
    icon: Icons.directions_car,
    color: Color(0xFF6A1B9A),
  ),
  DefaultCategory(
    name: 'Clothing',
    type: 'expense',
    icon: Icons.checkroom,
    color: Color(0xFFFF9800),
  ),
  DefaultCategory(
    name: 'Education',
    type: 'expense',
    icon: Icons.school,
    color: Color(0xFF3949AB),
  ),
  DefaultCategory(
    name: 'Electronics',
    type: 'expense',
    icon: Icons.devices,
    color: Color(0xFF00897B),
  ),
  DefaultCategory(
    name: 'Entertainment',
    type: 'expense',
    icon: Icons.movie,
    color: Color(0xFFAB47BC),
  ),
  DefaultCategory(
    name: 'Food',
    type: 'expense',
    icon: Icons.restaurant,
    color: Color(0xFFE53935),
  ),
  DefaultCategory(
    name: 'Health',
    type: 'expense',
    icon: Icons.favorite,
    color: Color(0xFFD81B60),
  ),
  DefaultCategory(
    name: 'Home',
    type: 'expense',
    icon: Icons.home,
    color: Color(0xFF5D4037),
  ),
  DefaultCategory(
    name: 'Insurance',
    type: 'expense',
    icon: Icons.verified_user,
    color: Color(0xFFFFA726),
  ),
  DefaultCategory(
    name: 'Shopping',
    type: 'expense',
    icon: Icons.shopping_bag,
    color: Color(0xFF1976D2),
  ),
  DefaultCategory(
    name: 'Social',
    type: 'expense',
    icon: Icons.group,
    color: Color(0xFF2E7D32),
  ),
  DefaultCategory(
    name: 'Sport',
    type: 'expense',
    icon: Icons.sports_soccer,
    color: Color(0xFF43A047),
  ),
  DefaultCategory(
    name: 'Tax',
    type: 'expense',
    icon: Icons.receipt,
    color: Color(0xFF8D6E63),
  ),
  DefaultCategory(
    name: 'Telephone',
    type: 'expense',
    icon: Icons.call,
    color: Color(0xFF303F9F),
  ),
];

// ✅ REMOVED: _defaultCategoryIconKeys (unused)

class _CategoryItem {
  final String id;
  final String type;
  String name;
  int iconIndex;
  String? iconId;
  int? iconColor;

  _CategoryItem({
    required this.id,
    required this.type,
    required this.name,
    required this.iconIndex,
    this.iconId,
    this.iconColor,
  });

  Map<String, dynamic> toDataMap() {
    return {
      'type': type,
      'name': name,
      'iconIndex': iconIndex,
      'iconId': iconId,
      'iconColor': iconColor,
    };
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();
  final ThemeService _themeService = ThemeService();

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
                            type: 'income',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: "Expense categories",
                            type: 'expense',
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
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildCategoryIconGrid({
    required String selectedId,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in kCategoryIconOptions)
          GestureDetector(
            onTap: () => onSelected(option.id),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: option.bgColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: selectedId == option.id
                      ? _themeService.primaryBlue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                option.icon,
                color: option.bgColor,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection({required String title, required String type}) {
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
        user == null
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Please log in to view categories.',
                  style: TextStyle(color: _themeService.textSub),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestoreService.streamCategoriesByType(
                  uid: user!.uid,
                  type: type,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No ${type.toLowerCase()} categories yet.',
                        style: TextStyle(color: _themeService.textSub),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final doc in docs)
                        Builder(
                          builder: (context) {
                            final data = doc.data();
                            return _buildCategoryRow(
                              category: _CategoryItem(
                                id: doc.id,
                                type: (data['type'] as String?) ?? type,
                                name: (data['name'] as String?) ?? 'Unnamed',
                                iconIndex:
                                    (data['iconIndex'] as num?)?.toInt() ?? 0,
                                iconId: data['iconId'] as String?,
                                iconColor: (data['iconColor'] as num?)?.toInt(),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
      ],
    );
  }

  Widget _buildCategoryRow({required _CategoryItem category}) {
    final iconOption = getCategoryIconOptionFromData(category.toDataMap());
    final iconColor = getCategoryIconBgColor(category.toDataMap());

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
              iconOption.icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                color: _themeService.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _themeService.textSub),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditCategoryDialog(category: category);
                  break;
                case 'delete':
                  _confirmDeleteCategory(category: category);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog({required _CategoryItem category}) {
    final TextEditingController nameController = TextEditingController(
      text: category.name,
    );
    final String selectedDefaultId =
        getCategoryIconOptionFromData(category.toDataMap()).id;
    String selectedIconId = category.iconId ?? selectedDefaultId;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _themeService.cardBg,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Edit category',
                        style: TextStyle(
                          color: _themeService.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: _themeService.cardBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.textSub.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.primaryBlue,
                          ),
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
                      child: _buildCategoryIconGrid(
                        selectedId: selectedIconId,
                        onSelected: (id) => setStateDialog(() {
                          selectedIconId = id;
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _themeService.textMain,
                              side: BorderSide(
                                color: _themeService.textSub.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final updatedName = nameController.text.trim();
                              final currentUser = user;

                              final selectedOption =
                                  getCategoryIconOptionById(selectedIconId);
                              final iconIndex = kCategoryIconOptions
                                  .indexOf(selectedOption);

                              if (updatedName.isEmpty || currentUser == null) {
                                Navigator.of(context).pop();
                                return;
                              }

                              _firestoreService.updateCategory(
                                uid: currentUser.uid,
                                categoryId: category.id,
                                name: updatedName,
                                iconIndex: iconIndex,
                                iconId: selectedOption.id,
                                iconColor: selectedOption.bgColor.toARGB32(),
                              );

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

  void _confirmDeleteCategory({required _CategoryItem category}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _themeService.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete category',
            style: TextStyle(
              color: _themeService.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${category.name}"?',
            style: TextStyle(color: _themeService.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: TextStyle(color: _themeService.textMain),
              ),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final currentUser = user;
                if (currentUser == null) {
                  navigator.pop();
                  return;
                }

                await _firestoreService.deleteCategory(
                  uid: currentUser.uid,
                  categoryId: category.id,
                );

                if (!mounted) return;
                navigator.pop();
              },
              child: Text(
                'DELETE',
                style: TextStyle(color: Colors.redAccent.shade200),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController nameController = TextEditingController();
    String selectedIconId = kCategoryIconOptions.first.id;
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedType == type
                                      ? _themeService.primaryBlue
                                      : _themeService.cardBg,
                                  foregroundColor: selectedType == type
                                      ? Colors.white
                                      : _themeService.textSub,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _themeService.textSub.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => selectedType = type),
                                child: Text(
                                  type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                            color: _themeService.textSub.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.primaryBlue,
                          ),
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
                      child: _buildCategoryIconGrid(
                        selectedId: selectedIconId,
                        onSelected: (id) => setState(() {
                          selectedIconId = id;
                        }),
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
                                color: _themeService.textSub.withValues(
                                  alpha: 0.3,
                                ),
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
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final name = nameController.text.trim();
                              final currentUser = user;
                              final selectedOption =
                                  getCategoryIconOptionById(selectedIconId);
                              final iconIndex = kCategoryIconOptions
                                  .indexOf(selectedOption);

                              if (name.isEmpty || currentUser == null) {
                                navigator.pop();
                                return;
                              }

                              final type = selectedType.toLowerCase();

                              await _firestoreService.addUserCategory(
                                uid: currentUser.uid,
                                name: name,
                                type: type,
                                iconIndex: iconIndex,
                                iconId: selectedOption.id,
                                iconColor: selectedOption.bgColor.toARGB32(),
                              );

                              if (!mounted) return;
                              navigator.pop();
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