import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/services/theme_service.dart';

class AddTransactionScreen extends StatefulWidget {
  // Optional parameters for Edit Mode
  final String? transactionId;
  final Map<String, dynamic>? transactionData;

  const AddTransactionScreen({
    super.key,
    this.transactionId,
    this.transactionData,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _descController = TextEditingController();

  String? _selectedAccountName;
  String? _selectedCategoryName;
  String? _selectedCategoryId;
  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();
  String _amountText = '';
  bool _isSaving = false;
  bool _isDeleting = false;

  final FirestoreService _firestoreService = FirestoreService();
  final ThemeService _themeService = ThemeService();
  final user = FirebaseAuth.instance.currentUser;

  // Helper to check if we are editing
  bool get isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if editing
    if (isEditing && widget.transactionData != null) {
      final data = widget.transactionData!;
      _selectedCategoryName = data['category'] ?? 'Uncategorized';
      _selectedCategoryId = data['categoryId'];
      _selectedAccountName = data['accountName'] ?? data['account'];
      _isExpense = (data['type'] ?? 'expense').toString() != 'income';

      if (data['date'] != null) {
        _selectedDate = (data['date'] as Timestamp).toDate();
      }

      _descController.text = data['name'] ?? '';

      // Handle amount (convert to string without negative sign for display)
      double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      _amountText = amount.abs().toString();

      // Remove decimal if it's .0
      if (_amountText.endsWith('.0')) {
        _amountText = _amountText.substring(0, _amountText.length - 2);
      }
    }
  }

  String get _displayAmount {
    if (_amountText.isEmpty) return '0';
    return _amountText;
  }

  String get _typeString => _isExpense ? 'expense' : 'income';

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'back') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
      } else if (value == '.') {
        if (!_amountText.contains('.')) {
          _amountText += value;
        }
      } else {
        if (_amountText.length < 10) {
          _amountText += value;
        }
      }
    });
  }

  Map<String, dynamic>? _buildTransactionData({required bool preserveCreatedAt}) {
    if (user == null) return null;

    if (_amountText.isEmpty || double.tryParse(_amountText) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return null;
    }

    if (_selectedAccountName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an account')),
      );
      return null;
    }

    if (_selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a category')),
      );
      return null;
    }

    if (_descController.text.isEmpty) {
      _descController.text = _selectedCategoryName ?? 'Transaction';
    }

    final double amount = double.parse(_amountText);
    final double finalAmount = _isExpense ? -amount : amount;
    final selectedCategoryName = _selectedCategoryName ?? 'Uncategorized';
    final selectedAccountName = _selectedAccountName ?? 'ACCOUNT';

    return {
      'userId': user!.uid,
      'uid': user!.uid,
      'amount': finalAmount,
      'type': _typeString,
      'category': selectedCategoryName,
      'categoryId': _selectedCategoryId,
      'accountName': selectedAccountName,
      'account': selectedAccountName,
      'name': _descController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate),
      'createdAt': preserveCreatedAt
          ? widget.transactionData?['createdAt'] ?? FieldValue.serverTimestamp()
          : FieldValue.serverTimestamp(),
    };
  }

  Future<void> _saveTransaction() async {
    setState(() => _isSaving = true);

    try {
      final data = _buildTransactionData(preserveCreatedAt: false);
      if (data == null) return;

      await FirebaseFirestore.instance.collection('transactions').add(data);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text('Transaction saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateTransaction() async {
    if (!isEditing) return;
    setState(() => _isSaving = true);

    try {
      final data = _buildTransactionData(preserveCreatedAt: true);
      if (data == null) return;

      await _firestoreService.updateTransaction(
        uid: user!.uid,
        transactionId: widget.transactionId!,
        data: data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTransaction() async {
    if (!isEditing) return;

    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transactionId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        setState(() => _isDeleting = false);
      }
    }
  }

  // ... (Selection Sheet Methods are same as before) ...
  void _showSelectionSheet({
    required String title,
    required List<String> items,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF051C3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        items[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        onSelect(items[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategorySheet() {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF051C3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Category",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestoreService.streamCategoriesByType(
                    uid: user!.uid,
                    type: _typeString,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No categories yet',
                          style: TextStyle(color: _themeService.textSub),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final categoryName = data['name'] ?? 'Unnamed';

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.category_rounded,
                                color: Colors.white),
                          ),
                          title: Text(
                            categoryName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCategoryName = categoryName;
                              _selectedCategoryId = doc.id;
                            });
                            Navigator.pop(context);
                          },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bgTop = const Color(0xFFE3F2FD);
    final Color bgBottom = const Color(0xFFF3F8FC);
    final Color primaryBlue = const Color(0xFF2979FF);
    final Color textDark = const Color(0xFF102027);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "CANCEL",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      isEditing ? "Edit Transaction" : "Add Transaction",
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _isSaving || _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEditing)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: _deleteTransaction,
                                ),
                              TextButton(
                                onPressed:
                                    isEditing ? _updateTransaction : _saveTransaction,
                                child: Text(
                                  "SAVE",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              // --- Scrollable Content ---
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // --- Type Toggle ---
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTypeButton("Expense", _isExpense),
                            const SizedBox(width: 20),
                            _buildTypeButton("Income", !_isExpense),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- Selectors ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSelector(
                                icon: Icons.account_balance_wallet,
                                label: _selectedAccountName ?? 'ACCOUNT',
                                onTap: () => _showSelectionSheet(
                                  title: "Select Account",
                                  items: ["Cash", "Bank", "Savings", "Card"],
                                  onSelect: (val) =>
                                      setState(() => _selectedAccountName = val),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSelector(
                                icon: Icons.category,
                                label: _selectedCategoryName ?? 'CATEGORY',
                                onTap: _showCategorySheet,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- Note Input ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _descController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "Add a note...",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(color: textDark, fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- Amount Display ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _displayAmount,
                              style: TextStyle(
                                color: textDark,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _onKeyTap('back'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.backspace_outlined,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Only show BIG save button at bottom if Editing (to make it easier)
                      if (isEditing)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "UPDATE TRANSACTION",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // --- Keypad (Fixed at Bottom) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECEF),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildKey("7"),
                        _buildKey("8"),
                        _buildKey("9"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildKey("4"),
                        _buildKey("5"),
                        _buildKey("6"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildKey("1"),
                        _buildKey("2"),
                        _buildKey("3"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildKey("."),
                        _buildKey("0"),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              height: 60,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('MMM dd').format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpense = label.toUpperCase() != 'INCOME';
        });
      },
      child: Row(
        children: [
          if (isSelected)
            Icon(Icons.check_circle, size: 18, color: const Color(0xFF2D79F6)),
          if (isSelected) const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF2D79F6) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF2D79F6).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2D79F6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(value),
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1E26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
