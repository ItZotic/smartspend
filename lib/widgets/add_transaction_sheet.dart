import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:smartspend/services/firestore_service.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _type = 'expense';
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _createCategory(User user) async {
    final controller = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('New Category'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Category name'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (result == null || result.trim().isEmpty) {
        return;
      }

      final categoryId = await _firestoreService.addOrGetCategory(
        uid: user.uid,
        name: result,
        type: _type,
      );

      if (!mounted) return;
      setState(() {
        _selectedCategoryId = categoryId;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save category: $e')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in')),
      );
      return;
    }

    final rawAmount = _amountController.text.trim();
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')), 
      );
      return;
    }

    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')), 
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestoreService.addTransaction(
        uid: user.uid,
        amount: amount,
        type: _type,
        categoryId: categoryId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        date: _selectedDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add transaction: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: mediaQuery.viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'expense', label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
              ButtonSegment<String>(value: 'income', label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
            ],
            selected: <String>{_type},
            onSelectionChanged: (selection) {
              setState(() {
                _type = selection.first;
                _selectedCategoryId = null;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₱ ',
            ),
          ),
          const SizedBox(height: 16),
          if (user == null)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('You must be signed in to manage categories'),
            )
          else
            Builder(
              builder: (context) {
                final currentUser = user!;
                return Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firestoreService.streamUserCategories(
                          uid: currentUser.uid,
                          type: _type,
                        ),
                        builder: (context, snapshot) {
                          final categories = snapshot.data?.docs ?? [];
                          return DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _selectedCategoryId,
                            items: categories
                                .map(
                                  (doc) => DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(doc.data()['name'] as String? ?? 'Unnamed'),
                                  ),
                                )
                                .toList(),
                            decoration: const InputDecoration(labelText: 'Category'),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _createCategory(currentUser),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('${_selectedDate.toLocal()}'.split(' ').first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
