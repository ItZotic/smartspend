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

  DateTime get _monthStart =>
      DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);

  DateTime get _nextMonthStart =>
      DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 1);

  String get _monthLabel => DateFormat.yMMMM().format(widget.selectedMonth);

  DateTime? _extractDate(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    if (createdAt is DateTime) return createdAt;

    final dateField = data['date'];
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is DateTime) return dateField;

    return null;
  }

  bool _isInSelectedMonth(Map<String, dynamic> data) {
    final date = _extractDate(data);
    if (date == null) return false;
    return !date.isBefore(_monthStart) && date.isBefore(_nextMonthStart);
  }

  String _formatCurrency(double value) => _themeService.formatCurrency(value);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
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
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Time selected: $_monthLabel',
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            centerTitle: false,
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
                        'Please log in to view category details.',
                        style: TextStyle(color: _themeService.textSub),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.streamTransactions(
                        uid: _user.uid,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: _themeService.primaryBlue,
                            ),
                          );
                        }

                        final transactions = snapshot.data?.docs ?? [];
                        final monthTransactions = transactions
                            .where((doc) => _isInSelectedMonth(doc.data()))
                            .toList();

                        double totalMonthExpenses = 0;
                        double categoryExpenses = 0;
                        final List<
                            QueryDocumentSnapshot<Map<String, dynamic>>>
                          categoryTxns = [];

                        for (final doc in monthTransactions) {
                          final data = doc.data();
                          final double amount =
                              (data['amount'] as num?)?.toDouble() ?? 0.0;
                          final type =
                              (data['type'] as String?)?.toLowerCase();
                          final String category =
                              (data['category'] as String?)?.trim().isNotEmpty ==
                                      true
                                  ? (data['category'] as String).trim()
                                  : 'Uncategorized';

                          final isExpense = type == 'expense' || amount < 0;

                          if (isExpense) {
                            final double expenseValue = amount.abs();
                            totalMonthExpenses += expenseValue;
                            if (category.toLowerCase() ==
                                widget.categoryName.toLowerCase()) {
                              categoryExpenses += expenseValue;
                              categoryTxns.add(doc);
                            }
                          }
                        }

                        categoryTxns.sort((a, b) {
                          final dateA = _extractDate(a.data()) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final dateB = _extractDate(b.data()) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return dateB.compareTo(dateA);
                        });

                        final double percent = totalMonthExpenses == 0
                            ? 0.0
                            : (categoryExpenses / totalMonthExpenses * 100.0);

                        return SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCard(percent, categoryExpenses),
                              const SizedBox(height: 16),
                              _buildTransactionList(categoryTxns),
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

  Widget _buildSummaryCard(double percent, double categoryExpenses) {
    final textColor = _themeService.textMain;
    final accentColor = _themeService.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0.0,
                    centerSpaceRadius: 40.0,
                    startDegreeOffset: -90.0,
                    sections: [
                      PieChartSectionData(
                        color: accentColor,
                        value: percent, // already double
                        radius: 20.0,
                        title: '${percent.toStringAsFixed(1)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      PieChartSectionData(
                        color: _themeService.textSub
                            .withValues(alpha: 0.2),
                        value: ((100.0 - percent)
                                .clamp(0.0, 100.0))
                            .toDouble(),
                        radius: 18.0,
                        title: '',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${percent.toStringAsFixed(2)}% of total expense in this period',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Expense in this period:',
                      style: TextStyle(
                        color: _themeService.textSub,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(categoryExpenses),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> categoryTxns,
  ) {
    if (categoryTxns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _themeService.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No transactions found for this category in the selected month.',
            style: TextStyle(color: _themeService.textSub),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final Map<DateTime,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};

    for (final doc in categoryTxns) {
      final data = doc.data();
      final date = _extractDate(data) ?? DateTime.now();
      final dateKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateKey, () => []).add(doc);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions',
          style: TextStyle(
            color: _themeService.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final date in sortedDates) ...[
          Text(
            DateFormat('MMM dd, EEEE').format(date),
            style: TextStyle(
              color: _themeService.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...grouped[date]!.map(
            (doc) => _buildTransactionTile(doc.data()),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> data) {
    final date = _extractDate(data) ?? DateTime.now();
    final double amount =
        (data['amount'] as num?)?.toDouble() ?? 0.0;
    final type = (data['type'] as String?)?.toLowerCase();
    final bool isExpense = type == 'expense' || amount < 0;
    final double expenseValue = amount.abs();

    final title = (data['note'] as String?)?.trim().isNotEmpty == true
        ? (data['note'] as String).trim()
        : (data['accountName'] as String?)?.trim().isNotEmpty == true
            ? (data['accountName'] as String).trim()
            : widget.categoryName;

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _themeService.primaryBlue
                  .withValues(alpha: 0.12),
            ),
            child: Icon(
              isExpense ? Icons.remove_circle : Icons.add_circle,
              color:
                  isExpense ? Colors.redAccent : Colors.greenAccent.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(date),
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(isExpense ? -expenseValue : expenseValue),
            style: TextStyle(
              color:
                  isExpense ? Colors.redAccent : Colors.greenAccent.shade400,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
