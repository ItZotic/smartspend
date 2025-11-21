import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/widgets/add_transaction.dart';
import 'package:smartspend/widgets/main_menu_drawers.dart';
import 'package:smartspend/services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final Function(String)? onNavigate;

  const HomeScreen({super.key, this.scrollController, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();
  final ThemeService _themeService = ThemeService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        // Colors from Service
        final Color bgTop = _themeService.bgTop;
        final Color bgBottom = _themeService.bgBottom;
        final Color primaryBlue = _themeService.primaryBlue;
        final Color textDark = _themeService.textMain;
        final Color sheetColor = _themeService.sheetColor;
        final Color activityBoxColor = _themeService.cardBg;

        if (user == null) return const Center(child: Text("Please log in."));

        return Scaffold(
          key: _scaffoldKey,
          drawer: const MainMenuDrawer(),

          body: Stack(
            children: [
              // Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgTop, bgBottom],
                  ),
                ),
              ),

              // Glows
              Positioned(
                top: -60,
                left: -60,
                child: _buildBlurCircle(primaryBlue.withOpacity(0.2), 300),
              ),
              Positioned(
                top: 200,
                right: -80,
                child: _buildBlurCircle(
                  Colors.cyanAccent.withOpacity(0.15),
                  250,
                ),
              ),

              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: activityBoxColor,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      _themeService.isDarkMode ? 0.3 : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 24,
                                color: textDark,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          Text(
                            "SmartSpend",
                            style: TextStyle(
                              color: textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const Spacer(),

                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _themeService.isDarkMode
                                    ? Colors.white24
                                    : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? Icon(Icons.person, color: primaryBlue)
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Balance Card (Kept blue in both modes)
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService.streamTransactions(
                          uid: user!.uid,
                        ),
                        builder: (context, snapshot) {
                          double totalBalance = 0;
                          if (snapshot.hasData) {
                            double income = 0;
                            double expense = 0;
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final amt =
                                  (data['amount'] as num?)?.toDouble() ?? 0.0;
                              if ((data['type'] ?? '')
                                      .toString()
                                      .toLowerCase() ==
                                  'income') {
                                income += amt.abs();
                              } else {
                                expense += amt.abs();
                              }
                            }
                            totalBalance = income - expense;
                          }

                          return Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF448AFF), Color(0xFF1565C0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -30,
                                  right: -30,
                                  child: _buildGlassCircle(180),
                                ),
                                Positioned(
                                  bottom: -50,
                                  left: -20,
                                  child: _buildGlassCircle(200),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(
                                            Icons.nfc,
                                            color: Colors.white70,
                                            size: 32,
                                          ),
                                          Container(
                                            width: 40,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.white38,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Total Balance",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // ✅ FIXED: Uses ThemeService formatter
                                          Text(
                                            _themeService.formatCurrency(
                                              totalBalance,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            user?.displayName?.toUpperCase() ??
                                                "CARD HOLDER",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const Text(
                                            "12/28",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Activities",
                            style: TextStyle(
                              color: textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.more_horiz,
                            color: _themeService.isDarkMode
                                ? Colors.white38
                                : Colors.grey[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGlassActivityBtn(
                            Icons.add,
                            "Top Up",
                            activityBoxColor,
                            primaryBlue,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(),
                                ),
                              );
                            },
                          ),
                          _buildGlassActivityBtn(
                            Icons.swap_horiz,
                            "Transfer",
                            activityBoxColor,
                            primaryBlue,
                            () {},
                          ),
                          _buildGlassActivityBtn(
                            Icons.file_download_outlined,
                            "Withdraw",
                            activityBoxColor,
                            primaryBlue,
                            () {},
                          ),
                          _buildGlassActivityBtn(
                            Icons.shopping_bag_outlined,
                            "Shop",
                            activityBoxColor,
                            primaryBlue,
                            () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              DraggableScrollableSheet(
                initialChildSize: 0.30,
                minChildSize: 0.30,
                maxChildSize: 0.9,
                builder:
                    (BuildContext context, ScrollController sheetController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: sheetColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: sheetColor.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white54,
                                  size: 32,
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28.0,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Transactions",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _firestoreService.streamTransactions(
                                  uid: user!.uid,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    );
                                  }

                                  final transactions =
                                      snapshot.data?.docs ?? [];

                                  if (transactions.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "No transactions yet",
                                        style: TextStyle(color: Colors.white38),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    controller: sheetController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 10,
                                    ),
                                    itemCount: transactions.length,
                                    itemBuilder: (context, index) {
                                      return _buildDarkTransactionTile(
                                        transactions[index],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGlassCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
    );
  }

  Widget _buildGlassActivityBtn(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: _themeService.isDarkMode
                  ? Colors.white
                  : const Color(0xFF0D1B2A),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _themeService.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkTransactionTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isExpense =
        (data['type'] ?? 'expense').toString().toLowerCase() == 'expense';
    final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final DateTime date =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    IconData icon = Icons.category;
    if (data['category'] == 'Food & Dining')
      icon = Icons.restaurant;
    else if (data['category'] == 'Transportation')
      icon = Icons.directions_car;
    else if (data['category'] == 'Salary')
      icon = Icons.work;
    else if (data['category'] == 'Entertainment')
      icon = Icons.movie;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(
              transactionId: doc.id,
              transactionData: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['category'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d • h:mm a').format(date),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // ✅ FIXED: Uses ThemeService formatter for list
            Text(
              (isExpense ? '- ' : '+ ') +
                  _themeService.formatCurrency(amount.abs()),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
