import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _category = 'Food & Dining';
  String _account = 'Cash';
  String _type = 'Expense'; // Expense or Income

  // amount as text that the number pad builds
  String _amountText = '';

  bool _isSaving = false;

  // helper to format display amount (red if expense)
  String get _displayAmount {
    if (_amountText.isEmpty) {
      return '₱0';
    }
    return '₱$_amountText';
  }

  void _appendDigit(String v) {
    setState(() {
      // limit length to prevent crazy long numbers
      if (_amountText.length >= 12) {
        return;
      }
      if (v == '.' && _amountText.contains('.')) {
        return;
      }
      _amountText += v;
    });
  }

  void _backspace() {
    if (_amountText.isEmpty) {
      return;
    }
    setState(() {
      _amountText = _amountText.substring(0, _amountText.length - 1);
    });
  }

  Future<void> _saveTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add transactions'),
        ),
      );
      return;
    }

    final desc = _descController.text.trim();
    final notes = _notesController.text.trim();
    final amountRaw = _amountText.trim();
    if (desc.isEmpty || amountRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter description and amount')),
      );
      return;
    }

    final amount = double.tryParse(amountRaw.replaceAll(',', ''));
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    final signedAmount = _type == 'Expense' ? -amount : amount;

    try {
      setState(() => _isSaving = true);
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'name': desc,
        'note': notes,
        'category': _category,
        'account': _account,
        'amount': signedAmount,
        'type': _type,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      Navigator.pop(context); // close page after save
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction added')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding transaction: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _numberKey(String label, {double size = 56}) {
    final icon = label == 'back' ? Icons.backspace_outlined : null;
    return GestureDetector(
      onTap: () {
        if (label == 'back') {
          _backspace();
        } else {
          _appendDigit(label);
        }
      },
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: icon == null
            ? Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(icon),
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF1A1A2E);
    const Color accentGreen = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: navy,
        centerTitle: true,
        title: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // toggle
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expense button
                    GestureDetector(
                      onTap: () => setState(() => _type = 'Expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _type == 'Expense'
                              ? Colors.redAccent.withValues(alpha: 0.9)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '− Expense',
                          style: TextStyle(
                            color: _type == 'Expense'
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _type = 'Income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _type == 'Income'
                              ? Colors.greenAccent.withValues(alpha: 0.9)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+ Income',
                          style: TextStyle(
                            color: _type == 'Income'
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // big amount display
              Center(
                child: Text(
                  _displayAmount,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _type == 'Expense' ? Colors.redAccent : Colors.green,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  hintText: 'Enter merchant or description',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Category
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: const [
                  DropdownMenuItem(
                    value: 'Food & Dining',
                    child: Text('Food & Dining'),
                  ),
                  DropdownMenuItem(
                    value: 'Transportation',
                    child: Text('Transportation'),
                  ),
                  DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                  DropdownMenuItem(
                    value: 'Entertainment',
                    child: Text('Entertainment'),
                  ),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Account
              const Text(
                'Account',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _account,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Savings', child: Text('Savings')),
                  DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                ],
                onChanged: (v) => setState(() => _account = v ?? _account),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional notes',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // number pad grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _numberKey('1'),
                  _numberKey('2'),
                  _numberKey('3'),
                  _numberKey('4'),
                  _numberKey('5'),
                  _numberKey('6'),
                  _numberKey('7'),
                  _numberKey('8'),
                  _numberKey('9'),
                  _numberKey('.'),
                  _numberKey('0'),
                  _numberKey('back'),
                ],
              ),

              const SizedBox(height: 18),

              // Add button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Add Transaction',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
