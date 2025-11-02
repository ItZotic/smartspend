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

          double totalIncome = 0;
          double totalExpense = 0;
          Map<String, double> spentByCategory = {
            for (var c in _categories) c: 0,
          };

          for (var doc in docs) {
            final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
            final category = doc['category'] ?? '';

            if (amount > 0) {
              totalIncome += amount;
            } else if (amount < 0) {
              totalExpense += amount.abs();
              spentByCategory[category] =
                  (spentByCategory[category] ?? 0) + amount.abs();
            }
          }

          double totalBudget = totalIncome;
          double totalSpent = totalExpense;
          double leftOverall = totalBudget - totalSpent;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(totalBudget, totalSpent, leftOverall),
              const SizedBox(height: 20),
              const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              for (var category in _categories)
                _buildCategoryCard(
                  category,
                  spentByCategory[category] ?? 0,
                  totalBudget,
                  _getIcon(category),
                ),
            ],
          );
        },
      ),
    );
  }

  // 🔹 Summary card
  Widget _buildSummaryCard(double totalBudget, double totalSpent, double left) {
    final percent = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

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
              Text("Total Budget\n₱${totalBudget.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("Total Spent\n₱${totalSpent.toStringAsFixed(2)}",
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

  // 🔹 Per-category card
  Widget _buildCategoryCard(String title, double spent, double totalBudget, IconData icon) {
    final percent = totalBudget > 0 ? (spent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final left = totalBudget - spent;

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
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green)),
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
