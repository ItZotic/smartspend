import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Please log in')));

    final stream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        centerTitle: true,
        title: const Text(
          'Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          double income = 0;
          double expenses = 0;
          final Map<String, double> categoryTotals = {};

          // For 6-month trend
          final now = DateTime.now();
          final Map<String, double> monthTotals = {}; // key YYYY-MM

          for (final doc in docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            final category = data['category'] ?? 'Other';
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
            if (amount > 0)
              income += amount;
            else
              expenses += amount.abs();

            final ts = data['createdAt'];
            DateTime dt = now;
            if (ts is Timestamp) dt = ts.toDate();
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            monthTotals[key] = (monthTotals[key] ?? 0) + amount;
          }

          // prepare 6 months keys oldest->newest
          List<String> last6 = [];
          for (int i = 5; i >= 0; i--) {
            final dt = DateTime(now.year, now.month - i, 1);
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            last6.add(key);
          }

          final monthValues = last6.map((k) => monthTotals[k] ?? 0.0).toList();

          // prepare pie sections from categoryTotals (absolute values)
          final pieSections = categoryTotals.entries.map((e) {
            final val = e.value.abs();
            return PieChartSectionData(
              value: val,
              color: val == 0
                  ? Colors.grey
                  : (e.value > 0 ? Colors.green : Colors.redAccent),
              radius: 50,
              title: '',
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _summaryBox(
                    'Income',
                    '₱${income.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _summaryBox(
                    'Expenses',
                    '₱${expenses.toStringAsFixed(2)}',
                    Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Expense Breakdown (pie)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expense Breakdown',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: PieChart(PieChartData(sections: pieSections)),
                    ),
                    const SizedBox(height: 12),
                    ...categoryTotals.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${e.key}: ₱${e.value.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: e.value < 0
                                ? Colors.redAccent
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6-Month Trend (line)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '6-Month Trend',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minY:
                              (monthValues.reduce((a, b) => a < b ? a : b)) *
                                  1.1 -
                              10,
                          maxY:
                              (monthValues.reduce((a, b) => a > b ? a : b)) *
                                  1.1 +
                              10,
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                monthValues.length,
                                (i) => FlSpot(i.toDouble(), monthValues[i]),
                              ),
                              isCurved: true,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, meta) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= last6.length)
                                    return const SizedBox();
                                  final key = last6[idx];
                                  final parts = key.split('-');
                                  final m = int.parse(parts[1]);
                                  final dt = DateTime(int.parse(parts[0]), m);
                                  final label =
                                      '${DateFormat.MMM().format(dt)}';
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(label),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "This month",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
