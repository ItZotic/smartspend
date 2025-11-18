import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ❗️ UPDATE THIS IMPORT to match your project
import 'package:smartspend/services/firestore_service.dart';

// --- This map holds our icon data ---
// We map a string name to an IconData
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

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  // --- This is the new function to show the dialog ---
  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    String selectedType = 'expense'; // Default to 'expense'
    String selectedIconString = 'category'; // Default icon

    showDialog(
      context: context,
      builder: (context) {
        // Use a StatefulWidget inside the dialog to manage state
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF42424A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                "Add new category",
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Type Selector (INCOME / EXPENSE) ---
                    const Text("Type", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: [
                        selectedType == 'income',
                        selectedType == 'expense',
                      ],
                      onPressed: (index) {
                        setDialogState(() {
                          selectedType = (index == 0) ? 'income' : 'expense';
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      selectedColor: const Color(0xFF36363E),
                      fillColor: Colors.white,
                      borderColor: Colors.white54,
                      selectedBorderColor: Colors.white,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("INCOME"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("EXPENSE"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Name Field ---
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Icon Grid ---
                    const Text("Icon", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150, // Fixed height for the grid
                      width: double.maxFinite,
                      child: GridView.builder(
                        itemCount: iconMap.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (context, index) {
                          String iconKey = iconMap.keys.elementAt(index);
                          IconData iconData = iconMap.values.elementAt(index);
                          bool isSelected = selectedIconString == iconKey;

                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedIconString = iconKey;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.white
                                  : const Color(0xFF50505A),
                              child: Icon(
                                iconData,
                                color: isSelected
                                    ? const Color(0xFF36363E)
                                    : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF36363E),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty)
                      return; // Simple validation

                    // Use the service to add the category
                    try {
                      await _firestoreService.addCategory(
                        uid: user!.uid,
                        name: nameController.text,
                        type: selectedType,
                        iconString: selectedIconString,
                      );
                      Navigator.of(context).pop(); // Close dialog on success
                    } catch (e) {
                      // Optional: Show error
                      print("Failed to add category: $e");
                    }
                  },
                  child: const Text("SAVE"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF36363E),
        body: Center(
          child: Text(
            "Please log in...",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF36363E),
      body: Column(
        // ⬅️ NEW: We use a Column
        children: [
          // This makes the list take up all available space
          Expanded(
            child: ListView(
              children: [
                _buildCategoryList(title: "Income categories", type: "income"),
                _buildCategoryList(
                  title: "Expense categories",
                  type: "expense",
                ),
              ],
            ),
          ),

          // --- THIS IS THE "ADD NEW CATEGORY" BUTTON ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("ADD NEW CATEGORY"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50505A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50), // Full width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _showAddCategoryDialog, // ⬅️ Calls our new function
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList({required String title, required String type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.streamUserCategories(
              uid: user!.uid,
              type: type,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No $type categories found.",
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }
              final categoryDocs = snapshot.data!.docs;
              return Column(
                children: categoryDocs
                    .map((doc) => _buildCategoryRow(doc))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(DocumentSnapshot categoryDoc) {
    final categoryData = categoryDoc.data() as Map<String, dynamic>;
    final categoryName = categoryData['name'] ?? 'Unnamed';

    // --- ❗️ NEW LOGIC ---
    // We read the 'icon' string, or use a default 'category'
    final iconString = categoryData['icon'] ?? 'category';
    final iconData = iconMap[iconString] ?? Icons.category; // Look up the icon

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF50505A),
            child: Icon(
              iconData,
              color: Colors.white,
            ), // Use the looked-up icon
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              categoryName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {
              /* TODO: Edit/Delete */
            },
          ),
        ],
      ),
    );
  }
}
