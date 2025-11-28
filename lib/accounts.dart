// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartspend/services/theme_service.dart';

class AccountsScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const AccountsScreen({super.key, this.scrollController});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final ThemeService _themeService = ThemeService();
  final user = FirebaseAuth.instance.currentUser;

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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Accounts",
                          style: TextStyle(
                            color: _themeService.textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded area with list and the full-width Add button
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('accounts')
                                .where('uid', isEqualTo: user!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final docs = snapshot.data?.docs ?? [];

                              if (docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No accounts added yet",
                                    style: TextStyle(
                                      color: _themeService.textSub,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: widget.scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      docs[index].data()
                                          as Map<String, dynamic>;
                                  final double balance =
                                      (data['balance'] as num?)?.toDouble() ??
                                      0.0;
                                  final String type =
                                      (data['type'] as String?) ?? 'Cash';
                                  final String name =
                                      (data['name'] as String?) ?? 'Account';

                                  return _buildAccountCard(
                                    name,
                                    balance,
                                    _getIconForAccount(type),
                                    docs[index].id,
                                    type,
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // The full-width "+ ADD NEW ACCOUNT" button (copied layout from Categories)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeService.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: _showAddAccountDialog,
                              icon: const Icon(Icons.add),
                              label: const Text(
                                "ADD NEW ACCOUNT",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // NOTE: FloatingActionButton removed as requested
        );
      },
    );
  }

  IconData _getIconForAccount(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('cash')) return Icons.money;
    if (t.contains('bank')) return Icons.account_balance;
    if (t.contains('credit')) return Icons.credit_card;
    if (t.contains('debit')) return Icons.credit_card;
    if (t.contains('wallet') || t.contains('e-wallet'))
      return Icons.account_balance_wallet;
    return Icons.account_box;
  }

  Widget _buildAccountCard(
    String name,
    double balance,
    IconData icon,
    String docId,
    String type,
  ) {
    return GestureDetector(
      // tap to edit
      onTap: () => _showEditAccountDialog(
        docId: docId,
        currentName: name,
        currentBalance: balance,
        currentType: type,
      ),
      // long press to delete (keeps your previous behavior)
      onLongPress: () => _showDeleteDialog(docId, name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _themeService.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                _themeService.isDarkMode ? 0.3 : 0.05,
              ),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _themeService.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _themeService.primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: _themeService.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Available Balance",
                    style: TextStyle(
                      color: _themeService.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _themeService.formatCurrency(balance),
              style: TextStyle(
                color: _themeService.textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ADD ACCOUNT DIALOG (same as before) ---
  void _showAddAccountDialog() {
    final nameCtrl = TextEditingController(text: "Cash");
    final amountCtrl = TextEditingController();
    String selectedType = "Cash";

    final List<String> accountTypes = [
      "Cash",
      "Bank",
      "Credit Card",
      "Debit Card",
      "E-Wallet",
      "Savings",
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
              Text(
                "Add Account",
                style: TextStyle(
                  color: _themeService.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 1. Account Type Dropdown
              Text(
                "Account Type",
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
                    value: selectedType,
                    dropdownColor: _themeService.cardBg,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: _themeService.primaryBlue,
                    ),
                    items: accountTypes
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
                        selectedType = val!;
                        if (val != "Custom") {
                          nameCtrl.text = val;
                        } else {
                          nameCtrl.clear();
                        }
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Name Input
              Text(
                "Account Name",
                style: TextStyle(color: _themeService.textSub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: _themeService.textMain),
                decoration: InputDecoration(
                  hintText: "e.g. My Savings",
                  hintStyle: TextStyle(color: _themeService.textSub),
                  filled: true,
                  fillColor: _themeService.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Balance Input
              Text(
                "Initial Balance",
                style: TextStyle(color: _themeService.textSub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _themeService.textMain),
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: TextStyle(color: _themeService.textSub),
                  filled: true,
                  fillColor: _themeService.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
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
                        amountCtrl.text.isNotEmpty &&
                        user != null) {
                      try {
                        final double initialBalance =
                            double.tryParse(amountCtrl.text) ?? 0.0;
                        final String accountName = nameCtrl.text;

                        // 1. Create Account Doc
                        await FirebaseFirestore.instance
                            .collection('accounts')
                            .add({
                              'uid': user!.uid,
                              'name': accountName,
                              'type': selectedType,
                              'balance': initialBalance,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                        // 2. AUTOMATICALLY ADD INITIAL TRANSACTION
                        if (initialBalance != 0) {
                          await FirebaseFirestore.instance
                              .collection('transactions')
                              .add({
                                'uid': user!.uid,
                                'userId': user!.uid,
                                'amount': initialBalance, // Positive for Income
                                'type': 'income',
                                'category': 'Initial Balance',
                                'account': accountName, // Link to this account
                                'name': 'Opening Balance',
                                'date': FieldValue.serverTimestamp(),
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                        }

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        // keep your existing error handling approach
                        print("Error adding account: $e");
                      }
                    }
                  },
                  child: const Text(
                    "SAVE ACCOUNT",
                    style: TextStyle(
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

  // --- EDIT ACCOUNT DIALOG (tap to edit) ---
  void _showEditAccountDialog({
    required String docId,
    required String currentName,
    required double currentBalance,
    required String currentType,
  }) {
    final nameCtrl = TextEditingController(text: currentName);
    final amountCtrl = TextEditingController(text: currentBalance.toString());
    String selectedType = currentType;

    final List<String> accountTypes = [
      "Cash",
      "Bank",
      "Credit Card",
      "Debit Card",
      "E-Wallet",
      "Savings",
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
              Text(
                "Edit Account",
                style: TextStyle(
                  color: _themeService.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 1. Account Type Dropdown
              Text(
                "Account Type",
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
                    value: selectedType,
                    dropdownColor: _themeService.cardBg,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: _themeService.primaryBlue,
                    ),
                    items: accountTypes
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
                        selectedType = val!;
                        if (val != "Custom") {
                          // automatically set name if user selected a preset
                          if (nameCtrl.text.trim().isEmpty) {
                            nameCtrl.text = val;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Name Input
              Text(
                "Account Name",
                style: TextStyle(color: _themeService.textSub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: _themeService.textMain),
                decoration: InputDecoration(
                  hintText: "e.g. My Savings",
                  hintStyle: TextStyle(color: _themeService.textSub),
                  filled: true,
                  fillColor: _themeService.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Balance Input
              Text(
                "Balance",
                style: TextStyle(color: _themeService.textSub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _themeService.textMain),
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: TextStyle(color: _themeService.textSub),
                  filled: true,
                  fillColor: _themeService.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
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
                    if (nameCtrl.text.isNotEmpty && user != null) {
                      try {
                        final double newBalance =
                            double.tryParse(amountCtrl.text) ?? 0.0;
                        final String newName = nameCtrl.text;

                        await FirebaseFirestore.instance
                            .collection('accounts')
                            .doc(docId)
                            .update({
                              'name': newName,
                              'type': selectedType,
                              'balance': newBalance,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        print("Error updating account: $e");
                      }
                    }
                  },
                  child: const Text(
                    "SAVE CHANGES",
                    style: TextStyle(
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

  void _showDeleteDialog(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _themeService.cardBg,
        title: Text(
          "Delete Account",
          style: TextStyle(color: _themeService.textMain),
        ),
        content: Text(
          "Delete $name? Note: This won't delete associated transactions.",
          style: TextStyle(color: _themeService.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('accounts')
                  .doc(docId)
                  .delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
