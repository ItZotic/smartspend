import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Make sure you add fl_chart: ^0.63.0 (or latest) in pubspec.yaml

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C2E),
        centerTitle: true,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIncomeExpenseSummary(),
          const SizedBox(height: 20),
          _buildExpenseBreakdown(),
          const SizedBox(height: 20),
          _buildTrendCard(),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryBox("Income", "₱25,000", Colors.green),
        _summaryBox("Expenses", "₱1,301", Colors.red),
      ],
    );
  }

  Widget _summaryBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text("This month", style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Expense Breakdown", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 65,
                    color: Colors.redAccent,
                    radius: 40,
                    title: '',
                  ),
                  PieChartSectionData(
                    value: 35,
                    color: Colors.blueAccent,
                    radius: 40,
                    title: '',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Food & Dining ₱850 (65%)"),
              Text("Transportation ₱450.50 (35%)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: const Text(
        "6-Month Trend (in thousands)\n\n[Chart Placeholder]",
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}
