import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartspend/services/theme_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final ThemeService _themeService = ThemeService();
  final user = FirebaseAuth.instance.currentUser;

  int _currentView = 0;
  String _sortBy = 'closest';

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
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _themeService.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: _themeService.textMain,
                            ),
                          ),
                        ),
                        Text(
                          "Subscriptions",
                          style: TextStyle(
                            color: _themeService.textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (_currentView == 0)
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _themeService.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.sort,
                                color: _themeService.textMain,
                                size: 20,
                              ),
                            ),
                            color: _themeService.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (val) => setState(() => _sortBy = val),
                            itemBuilder: (context) => [
                              _buildPopupItem(
                                'closest',
                                "Closest Billing",
                                Icons.calendar_today,
                              ),
                              _buildPopupItem(
                                'price_high',
                                "Price: High to Low",
                                Icons.arrow_upward,
                              ),
                              _buildPopupItem(
                                'price_low',
                                "Price: Low to High",
                                Icons.arrow_downward,
                              ),
                              _buildPopupItem(
                                'name',
                                "Name (A-Z)",
                                Icons.sort_by_alpha,
                              ),
                            ],
                          )
                        else
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- Custom Toggle (Subs | Edit & Sort) ---
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(4),
                    height: 50,
                    decoration: BoxDecoration(
                      // ✅ FIXED: Dynamic background color for the toggle container
                      color: _themeService.cardBg,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildToggleBtn("Subs", 0),
                        _buildToggleBtn("Edit & Sort", 1),
                      ],
                    ),
                  ),

                  // --- Main Content Area ---
                  Expanded(
                    child: _currentView == 0
                        ? _buildDashboardView()
                        : _buildEditView(),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: _currentView == 0
              ? FloatingActionButton(
                  backgroundColor: _themeService.primaryBlue,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showSubscriptionDialog(null),
                )
              : null,
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    String text,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: _themeService.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: _themeService.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String text, int index) {
    final bool isSelected = _currentView == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentView = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? _themeService.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              // ✅ FIXED: Text color logic.
              // If selected: White (on blue bg).
              // If NOT selected: Use theme's secondary text color (readable on dark/light bg).
              color: isSelected ? Colors.white : _themeService.textSub,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------
  // VIEW 1: DASHBOARD
  // -----------------------------------------
  Widget _buildDashboardView() {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .where('uid', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty)
          return Center(
            child: Text(
              "No subscriptions yet",
              style: TextStyle(color: _themeService.textSub),
            ),
          );

        double totalMonthly = 0;
        List<Map<String, dynamic>> upcoming = [];
        final now = DateTime.now();

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalMonthly += (data['amount'] as num?)?.toDouble() ?? 0.0;

          int day = data['paymentDay'] ?? 1;
          DateTime billingDate = DateTime(now.year, now.month, day);
          if (billingDate.isBefore(DateTime(now.year, now.month, now.day))) {
            billingDate = DateTime(now.year, now.month + 1, day);
          }
          int daysLeft = billingDate.difference(now).inDays + 1;
          if (billingDate.day == now.day) daysLeft = 0;

          data['daysLeft'] = daysLeft;
          upcoming.add(data);
        }

        upcoming.sort(
          (a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int),
        );

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF448AFF), Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Monthly Spend",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _themeService.formatCurrency(totalMonthly),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("Active Subs", "${docs.length}"),
                      _buildStat(
                        "Yearly Cost",
                        _themeService.formatCurrency(totalMonthly * 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(
              "Upcoming Bills",
              style: TextStyle(
                color: _themeService.textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (upcoming.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "No upcoming bills",
                    style: TextStyle(color: _themeService.textSub),
                  ),
                ),
              )
            else
              ...upcoming
                  .take(3)
                  .map((data) => _buildUpcomingCard(data))
                  .toList(),

            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  // -----------------------------------------
  // VIEW 2: EDIT & SORT MODE
  // -----------------------------------------
  Widget _buildEditView() {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .where('uid', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty)
          return Center(
            child: Text(
              "No subscriptions to edit",
              style: TextStyle(color: _themeService.textSub),
            ),
          );

        List<Map<String, dynamic>> sortedList = [];
        final now = DateTime.now();

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          int day = data['paymentDay'] ?? 1;
          DateTime billingDate = DateTime(now.year, now.month, day);
          if (billingDate.isBefore(DateTime(now.year, now.month, now.day))) {
            billingDate = DateTime(now.year, now.month + 1, day);
          }
          int daysLeft = billingDate.difference(now).inDays + 1;
          if (billingDate.day == now.day) daysLeft = 0;
          data['daysLeft'] = daysLeft;

          sortedList.add(data);
        }

        sortedList.sort((a, b) {
          switch (_sortBy) {
            case 'price_high':
              return (b['amount'] as num).compareTo(a['amount'] as num);
            case 'price_low':
              return (a['amount'] as num).compareTo(b['amount'] as num);
            case 'name':
              return (a['name'] as String).toLowerCase().compareTo(
                (b['name'] as String).toLowerCase(),
              );
            case 'closest':
            default:
              return (a['daysLeft'] as int).compareTo(b['daysLeft'] as int);
          }
        });

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Manage Subscriptions",
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Sort: $_sortBy",
                  style: TextStyle(
                    color: _themeService.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedList.map((data) {
              final doc = docs.firstWhere((d) => d.id == data['id']);
              return GestureDetector(
                onTap: () => _showSubscriptionDialog(doc),
                child: _buildEditCard(data),
              );
            }).toList(),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic> data) {
    final int days = data['daysLeft'];
    final String timeText = days == 0
        ? "Renewing Today"
        : "Renewing in $days days";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildServiceIcon(data['name']),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Subscription',
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    color: days <= 3 ? Colors.redAccent : _themeService.textSub,
                    fontSize: 12,
                    fontWeight: days <= 3 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _themeService.formatCurrency((data['amount'] as num).toDouble()),
            style: TextStyle(
              color: _themeService.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _themeService.primaryBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _themeService.primaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildServiceIcon(data['name']),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Subscription',
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Billing Day: ${data['paymentDay']} • ${_themeService.formatCurrency((data['amount'] as num).toDouble())}",
                  style: TextStyle(color: _themeService.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_note, color: _themeService.primaryBlue, size: 28),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(String? name) {
    Color brandColor = _themeService.primaryBlue;
    IconData brandIcon = Icons.subscriptions;
    final lowerName = (name ?? '').toLowerCase();

    if (lowerName.contains('netflix')) {
      brandColor = Colors.red;
      brandIcon = Icons.movie;
    } else if (lowerName.contains('spotify')) {
      brandColor = Colors.green;
      brandIcon = Icons.music_note;
    } else if (lowerName.contains('youtube')) {
      brandColor = Colors.redAccent;
      brandIcon = Icons.play_circle_filled;
    } else if (lowerName.contains('apple')) {
      brandColor = Colors.black;
      brandIcon = Icons.music_note;
    } else if (lowerName.contains('disney')) {
      brandColor = Colors.blueAccent;
      brandIcon = Icons.tv;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brandColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(brandIcon, color: brandColor, size: 24),
    );
  }

  void _showSubscriptionDialog(DocumentSnapshot? doc) {
    final isEditing = doc != null;
    final data = isEditing ? doc.data() as Map<String, dynamic> : null;

    final nameCtrl = TextEditingController(
      text: isEditing ? data!['name'] : "",
    );
    final amountCtrl = TextEditingController(
      text: isEditing ? data!['amount'].toString() : "",
    );
    final dayCtrl = TextEditingController(
      text: isEditing ? data!['paymentDay'].toString() : "",
    );

    String selectedService = "Custom";
    if (isEditing &&
        [
          "Netflix",
          "Spotify",
          "YouTube Premium",
          "Disney+",
          "Amazon Prime",
          "Apple Music",
        ].contains(data!['name'])) {
      selectedService = data['name'];
    }

    final List<String> popularServices = [
      "Netflix",
      "Spotify",
      "YouTube Premium",
      "Disney+",
      "Amazon Prime",
      "Apple Music",
      "Custom",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _themeService.sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? "Edit Subscription" : "Add Subscription",
                    style: TextStyle(
                      color: _themeService.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('subscriptions')
                            .doc(doc.id)
                            .delete();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                "Service Name",
                style: TextStyle(color: _themeService.textSub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _themeService.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _themeService.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedService,
                    dropdownColor: _themeService.cardBg,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: _themeService.primaryBlue,
                    ),
                    items: popularServices
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(color: _themeService.textMain),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedService = val!;
                        if (val != "Custom")
                          nameCtrl.text = val;
                        else
                          nameCtrl.clear();
                      });
                    },
                  ),
                ),
              ),

              if (selectedService == "Custom") ...[
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: _themeService.textMain),
                  decoration: InputDecoration(
                    hintText: "Name",
                    hintStyle: TextStyle(color: _themeService.textSub),
                    filled: true,
                    fillColor: _themeService.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: _themeService.textMain),
                      decoration: InputDecoration(
                        hintText: "Amount",
                        hintStyle: TextStyle(color: _themeService.textSub),
                        filled: true,
                        fillColor: _themeService.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dayCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: _themeService.textMain),
                      decoration: InputDecoration(
                        hintText: "Day (1-31)",
                        hintStyle: TextStyle(color: _themeService.textSub),
                        filled: true,
                        fillColor: _themeService.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeService.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty &&
                        amountCtrl.text.isNotEmpty) {
                      try {
                        final double amt =
                            double.tryParse(amountCtrl.text) ?? 0.0;
                        final int day = int.tryParse(dayCtrl.text) ?? 1;

                        final newData = {
                          'uid': user!.uid,
                          'name': nameCtrl.text,
                          'amount': amt,
                          'paymentDay': day,
                          'cycle': 'Monthly',
                          'createdAt': FieldValue.serverTimestamp(),
                        };

                        if (isEditing) {
                          await FirebaseFirestore.instance
                              .collection('subscriptions')
                              .doc(doc.id)
                              .update(newData);
                        } else {
                          await FirebaseFirestore.instance
                              .collection('subscriptions')
                              .add(newData);
                        }

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        print(e);
                      }
                    }
                  },
                  child: Text(
                    isEditing ? "UPDATE" : "SAVE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
