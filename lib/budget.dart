import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for text input formatter
// ❗️ UPDATE THIS IMPORT to match your project
import 'package:smartspend/services/firestore_service.dart';

// --- 🔽 NEW: This map is now needed here too ---
// This ensures your icons are consistent everywhere.
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

  final DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Please log in to view your budget."));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF36363E), // Dark grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFF36363E), // Dark app bar
        elevation: 0,
        centerTitle: true,
        leading: Icon(Icons.menu, color: Colors.white),
        title: const Text(
          'MyMoney',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        controller: widget.scrollController,
        children: [
          _buildMonthSelector(),
          _buildBudgetSummary(),
          _buildCategoryList(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
            onPressed: () {
              // TODO: Implement month change logic
            },
          ),
          Text(
            "November, 2025", // We'll update this later
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
            onPressed: () {
              // TODO: Implement month change logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary() {
    // TODO: You will need to fetch real data here later
    String totalBudget = "0.00";
    String totalSpent = "0.00";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                "TOTAL BUDGET",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "₱$totalBudget",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                "TOTAL SPENT",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "₱$totalSpent",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
        type: 'expense', // Budget screen only shows expense categories
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No expense categories found.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final categoryDocs = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Not budgeted this month",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              // Build a list from the documents
              ...categoryDocs.map((doc) {
                return _buildCategoryRow(doc);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // 🔽 --- THIS WIDGET IS NOW FIXED --- 🔽
  Widget _buildCategoryRow(DocumentSnapshot categoryDoc) {
    final categoryData = categoryDoc.data() as Map<String, dynamic>;
    final categoryName = categoryData['name'] ?? 'Unnamed';
    final categoryId = categoryDoc.id;

    // --- ❗️ UPDATED LOGIC ---
    // Read the 'icon' string from the document
    final iconString = categoryData['icon'] ?? 'category';
    // Look up the IconData from our map
    final iconData = iconMap[iconString] ?? Icons.category;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF50505A),
            child: Icon(iconData, color: Colors.white), // Use the correct icon
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              categoryName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF50505A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _showSetBudgetDialog(
                categoryId,
                categoryName,
                iconData,
              ); // Pass icon
            },
            child: Text("SET BUDGET"),
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
          backgroundColor: Color(0xFF42424A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Set budget", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF50505A),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                    ), // Use passed icon
                  ),
                  const SizedBox(width: 12),
                  Text(
                    categoryName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: limitController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Limit",
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixText: "₱",
                  prefixStyle: TextStyle(color: Colors.white, fontSize: 18),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Month: November, 2025", // TODO: Use dynamic month
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("CANCEL", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF36363E),
              ),
              onPressed: () async {
                final limit = double.tryParse(limitController.text);
                if (limit == null || limit <= 0) {
                  return;
                }

                try {
                  await _firestoreService.setBudget(
                    uid: user!.uid,
                    categoryId: categoryId,
                    categoryName: categoryName,
                    limit: limit,
                    month: _currentMonth,
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  print("Failed to set budget: $e");
                }
              },
              child: Text("SET"),
            ),
          ],
        );
      },
    );
  }

  // --- 🗑 REMOVED ---
  // The old _getIcon function is no longer needed.
}
