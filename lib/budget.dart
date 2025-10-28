import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildCategoryCard("Food & Dining", "₱850.00", "₱10,000.00", 0.09, "₱9,150 left", Icons.restaurant),
          _buildCategoryCard("Transportation", "₱450.50", "₱6,000.00", 0.08, "₱5,549.5 left", Icons.directions_car),
          _buildCategoryCard("Entertainment", "₱0.00", "₱3,000.00", 0.0, "₱3,000 left", Icons.movie),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("October Budget Summary", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Total Budget\n₱24,000.00", style: TextStyle(fontWeight: FontWeight.w500)),
              Text("Total Spent\n₱1,300.50", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Overall Progress"),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: 0.05,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String spent, String total, double percent, String left, IconData icon) {
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
              Text(spent, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
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
            child: Text("${(percent * 100).toStringAsFixed(0)}% used", style: const TextStyle(fontSize: 12)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(left, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
