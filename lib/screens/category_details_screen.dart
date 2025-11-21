import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/services/theme_service.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final String categoryName;
  final DateTime selectedMonth;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryName,
    required this.selectedMonth,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  final ThemeService _themeService = ThemeService();
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  DateTime get _startOfMonth =>
      DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);

  DateTime get _startOfNextMonth =>
      DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 1);

  DateTime? _extractDate(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    if (createdAt is DateTime) return createdAt;

    final dateField = data['date'];
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is DateTime) return dateField;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: _themeService.textMain),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Time selected: ${DateFormat.yMMMM().format(widget.selectedMonth)}',
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_themeService.bgTop, _themeService.bgBottom],
              ),
            ),
            child: SafeArea(
              child: _user == null
                  ? Center(
                      child: Text(
                        'Please log in to view this category.',
                        style: TextStyle(color: _themeService.textMain),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.streamTransactions(uid: _user!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: _themeService.primaryBlue,
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final monthTransactions = docs.where((doc) {
                          final data = doc.data();
                          final date = _extractDate(data);
                          final category =
                              (data['category'] as String?)?.trim().toLowerCase() ?? '';
                          return date != null &&
                              !date.isBefore(_startOfMonth) &&
                              date.isBefore(_startOfNextMonth) &&
                              category == widget.categoryName.toLowerCase();
                        }).toList();

                        final totalExpenses = docs.fold<double>(0, (sum, doc) {
                          final data = doc.data();
                          final date = _extractDate(data);
                          if (date == null ||
                              date.isBefore(_startOfMonth) ||
                              !date.isBefore(_startOfNextMonth)) {
                            return sum;
                          }
                          final double amount = (data['amount'] as num?)?.toDouble() ?? 0;
                          final String type =
                              (data['type'] as String?)?.toLowerCase() ?? '';
                          if (type == 'expense') {
                            return sum + amount.abs();
                          }
                          if (type == 'income') {
                            return sum;
                          }
                          return amount < 0 ? sum + amount.abs() : sum;
                        });

                        double categoryExpense = 0;
                        for (final doc in monthTransactions) {
                          final data = doc.data();
                          final double amount = (data['amount'] as num?)?.toDouble() ?? 0;
                          final String type =
                              (data['type'] as String?)?.toLowerCase() ?? '';
                          if (type == 'income') continue;
                          categoryExpense += amount.abs();
                        }

                        final percent = totalExpenses == 0
                            ? 0
                            : (categoryExpense / totalExpenses * 100);

                        final grouped = <DateTime, List<Map<String, dynamic>>>{};
                        for (final doc in monthTransactions) {
                          final data = doc.data();
                          final date = _extractDate(data) ?? DateTime.now();
                          final dayKey = DateTime(date.year, date.month, date.day);
                          grouped.putIfAbsent(dayKey, () => []).add(data);
                        }

                        final orderedDays = grouped.keys.toList()
                          ..sort((a, b) => b.compareTo(a));

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSummaryCard(categoryExpense, percent),
                              const SizedBox(height: 16),
                              ...orderedDays.map((day) {
                                final transactions = grouped[day]!
                                  ..sort((a, b) {
                                    final dateA = _extractDate(a) ?? DateTime.now();
                                    final dateB = _extractDate(b) ?? DateTime.now();
                                    return dateB.compareTo(dateA);
                                  });
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('MMM dd, EEEE').format(day),
                                      style: TextStyle(
                                        color: _themeService.textMain,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...transactions.map((data) => _buildTransactionTile(data)),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              }),
                              if (monthTransactions.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Center(
                                    child: Text(
                                      'No transactions for this category this month.',
                                      style: TextStyle(color: _themeService.textSub),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(double categoryExpense, double percent) {
    final cardColor = _themeService.cardBg;
    final textColor = _themeService.textMain;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense in this period',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: percent.clamp(0, 100),
                    color: _themeService.primaryBlue,
                    radius: 60,
                    title: '${percent.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    titlePositionPercentageOffset: 0.55,
                  ),
                  PieChartSectionData(
                    value: (100 - percent).clamp(0, 100),
                    color: _themeService.textSub.withValues(alpha: 0.2),
                    radius: 60,
                    title: '',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(symbol: '₱').format(categoryExpense),
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${percent.toStringAsFixed(2)}% of total expense in this period',
            style: TextStyle(
              color: _themeService.textSub,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> data) {
    final date = _extractDate(data) ?? DateTime.now();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final String note = (data['note'] as String?)?.trim();
    final String account = (data['accountName'] as String?)?.trim();
    final String description =
        (note?.isNotEmpty == true ? note : account) ?? 'No note';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _themeService.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              amount < 0 ? Icons.remove_circle : Icons.add_circle,
              color: _themeService.textMain,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(date),
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '₱').format(amount),
            style: TextStyle(
              color: amount < 0 ? Colors.redAccent : Colors.greenAccent.shade400,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
