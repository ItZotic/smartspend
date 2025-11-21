import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/services/theme_service.dart';

final Map<String, IconData> iconMap = {
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'movie': Icons.movie,
  'child_care': Icons.child_care,
  'face': Icons.face,
  'receipt': Icons.receipt,
  'directions_car_filled': Icons.directions_car_filled,
  'checkroom': Icons.checkroom,
  'school': Icons.school,
  'devices': Icons.devices,
  'emoji_events': Icons.emoji_events,
  'local_offer': Icons.local_offer,
  'confirmation_number': Icons.confirmation_number,
  'replay': Icons.replay,
  'house': Icons.house,
  'work': Icons.work,
  'trending_up': Icons.trending_up,
  'health': Icons.favorite,
  'home': Icons.home,
  'insurance': Icons.shield,
  'shopping': Icons.shopping_cart,
  'social': Icons.people,
  'sport': Icons.sports_tennis,
  'tax': Icons.account_balance,
  'telephone': Icons.phone,
  'category': Icons.category,
};

class BudgetScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const BudgetScreen({super.key, this.scrollController});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();
  final ThemeService _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        if (user == null) {
          return const Center(
            child: Text("Please log in to view your budget."),
          );
        }

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
                    child: Center(
                      child: Text(
                        "Budgets",
                        style: TextStyle(
                          color: _themeService.textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildMonthSelector(),
                        const SizedBox(height: 20),
                        _buildBudgetSummary(),
                        const SizedBox(height: 24),
                        _buildCategoryList(),
                        const SizedBox(height: 80),
                      ],
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

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _themeService.textMain.withValues(alpha: 0.7),
            size: 18,
          ),
          onPressed: () {},
        ),
        Text(
          "November, 2025",
          style: TextStyle(
            color: _themeService.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            color: _themeService.textMain.withValues(alpha: 0.7),
            size: 18,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBudgetSummary() {
    // In a real app, you'd calculate these
    double totalBudget = 0.00;
    double totalSpent = 0.00;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              _themeService.isDarkMode ? 0.3 : 0.05,
            ),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                "TOTAL BUDGET",
                style: TextStyle(
                  color: _themeService.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _themeService.formatCurrency(totalBudget), // Updated
                style: TextStyle(
                  color: _themeService.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: _themeService.textSub.withValues(alpha: 0.2),
          ),
          Column(
            children: [
              Text(
                "TOTAL SPENT",
                style: TextStyle(
                  color: _themeService.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _themeService.formatCurrency(totalSpent), // Updated
                style: TextStyle(
                  color: _themeService.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.streamUserCategories(
        uid: user!.uid,
        type: 'expense',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final categoryDocs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Not budgeted this month",
              style: TextStyle(
                color: _themeService.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (categoryDocs.isEmpty)
              Center(
                child: Text(
                  "No categories yet",
                  style: TextStyle(color: _themeService.textSub),
                ),
              ),
            ...categoryDocs.map((doc) {
              return _buildCategoryRow(doc);
            }),
          ],
        );
      },
    );
  }

  Widget _buildCategoryRow(DocumentSnapshot categoryDoc) {
    final categoryData = categoryDoc.data() as Map<String, dynamic>;
    final categoryName = categoryData['name'] ?? 'Unnamed';
    final categoryId = categoryDoc.id;
    final iconString = categoryData['icon'] ?? 'category';
    final iconData = iconMap[iconString] ?? Icons.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _themeService.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: _themeService.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              categoryName,
              style: TextStyle(
                color: _themeService.textMain,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeService.bgBottom,
              foregroundColor: _themeService.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _themeService.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
            ),
            onPressed: () {
              _showSetBudgetDialog(categoryId, categoryName, iconData);
            },
            child: const Text(
              "SET BUDGET",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetBudgetDialog(
    String categoryId,
    String categoryName,
    IconData iconData,
  ) {
    final TextEditingController limitController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _themeService.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Set budget",
            style: TextStyle(color: _themeService.textMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _themeService.primaryBlue.withValues(alpha: 0.1),
                    child: Icon(iconData, color: _themeService.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    categoryName,
                    style: TextStyle(
                      color: _themeService.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: limitController,
                style: TextStyle(color: _themeService.textMain),
                decoration: InputDecoration(
                  labelText: "Limit",
                  labelStyle: TextStyle(color: _themeService.textSub),
                  // Updated prefix to use ThemeService currency symbol
                  prefixText: _themeService.currencySymbol,
                  prefixStyle: TextStyle(
                    color: _themeService.textMain,
                    fontSize: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _themeService.textSub.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _themeService.primaryBlue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: TextStyle(color: _themeService.textSub),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeService.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Add your save logic here
                Navigator.of(context).pop();
              },
              child: const Text("SET"),
            ),
          ],
        );
      },
    );
  }
}
