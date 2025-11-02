import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final List<String> _categories = [
    "Food & Dining",
    "Transportation",
    "Entertainment",
  ];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Please log in to view your budget."));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C2E),
        title: const Text('Budgets', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Track total income & expenses PER CATEGORY
          Map<String, double> incomeByCategory = {
            for (var c in _categories) c: 0,
          };
          Map<String, double> expenseByCategory = {
            for (var c in _categories) c: 0,
          };

          for (var doc in docs) {
            final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
            final category = doc['category'] ?? '';

            if (_categories.contains(category)) {
              if (amount > 0) {
                incomeByCategory[category] =
                    (incomeByCategory[category] ?? 0) + amount;
              } else if (amount < 0) {
                expenseByCategory[category] =
                    (expenseByCategory[category] ?? 0) + amount.abs();
              }
            }
          }

          // Compute overall totals (just for summary)
          double totalIncome = incomeByCategory.values.fold(0, (a, b) => a + b);
          double totalExpense = expenseByCategory.values.fold(0, (a, b) => a + b);
          double totalLeft = totalIncome - totalExpense;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(totalIncome, totalExpense, totalLeft),
              const SizedBox(height: 20),
              const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              for (var category in _categories)
                _buildCategoryCard(
                  category,
                  incomeByCategory[category]!,
                  expenseByCategory[category]!,
                  _getIcon(category),
                ),
            ],
          );
        },
      ),
    );
  }

  // 🔹 Summary card (overall)
  Widget _buildSummaryCard(double totalIncome, double totalExpense, double left) {
    final percent =
        totalIncome > 0 ? (totalExpense / totalIncome).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Overall Budget Summary", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Income\n₱${totalIncome.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("Total Spent\n₱${totalExpense.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Overall Progress"),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text("₱${left.toStringAsFixed(2)} left",
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // 🔹 Category card (individual)
  Widget _buildCategoryCard(
      String title, double income, double spent, IconData icon) {
    final left = (income - spent).clamp(0, double.infinity);
    final percent = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[800]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text("₱${spent.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("${(percent * 100).toStringAsFixed(0)}% used",
                style: const TextStyle(fontSize: 12)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text("₱${left.toStringAsFixed(2)} left",
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }
}
