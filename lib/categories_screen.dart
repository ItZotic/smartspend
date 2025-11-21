import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/services/theme_service.dart';

// Make sure iconMap is available here or imported
final Map<String, IconData> iconMap = {
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'movie': Icons.movie,
  'child_care': Icons.child_care,
  'face': Icons.face,
  'receipt': Icons.receipt,
  'category': Icons.category,
  // ... (add rest)
};

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
        if (user == null) return const Center(child: Text("Log in"));

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
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildCategoryList(
                          title: "Income categories",
                          type: "income",
                        ),
                        const SizedBox(height: 20),
                        _buildCategoryList(
                          title: "Expense categories",
                          type: "expense",
                        ),
                        const SizedBox(height: 100),
                      ],
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
                /* Show Add Dialog logic from before, but apply theme colors to dialog */
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

  Widget _buildCategoryList({required String title, required String type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _themeService.textSub,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.streamUserCategories(
            uid: user!.uid,
            type: type,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final categoryDocs = snapshot.data!.docs;
            return Column(
              children: categoryDocs
                  .map((doc) => _buildCategoryRow(doc))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryRow(DocumentSnapshot categoryDoc) {
    final categoryData = categoryDoc.data() as Map<String, dynamic>;
    final categoryName = categoryData['name'] ?? 'Unnamed';
    final iconString = categoryData['icon'] ?? 'category';
    final iconData = iconMap[iconString] ?? Icons.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              _themeService.isDarkMode ? 0.2 : 0.03,
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
              color: _themeService.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: _themeService.primaryBlue, size: 20),
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
          Icon(Icons.more_vert, color: _themeService.textSub),
        ],
      ),
    );
  }
}
