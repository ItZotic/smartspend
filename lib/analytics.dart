import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspend/screens/category_details_screen.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/services/theme_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const AnalyticsScreen({super.key, this.scrollController});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ThemeService _themeService = ThemeService();
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime get _startOfSelectedMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _startOfNextMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

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
        if (_user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in to view analytics.'),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_themeService.bgTop, _themeService.bgBottom],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Analytics",
                          style: TextStyle(
                            color: _themeService.textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildMonthSelector(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream:
                          _firestoreService.streamTransactions(uid: _user!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: _themeService.primaryBlue,
                            ),
                          );
                        }

                        final transactions = snapshot.data?.docs ?? [];
                        final monthTransactions = transactions.where((doc) {
                          final date = _extractDate(doc.data());
                          if (date == null) return false;
                          return !date.isBefore(_startOfSelectedMonth) &&
                              date.isBefore(_startOfNextMonth);
                        }).toList();

                        return SingleChildScrollView(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: _buildAnalyticsBody(monthTransactions),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsBody(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> monthTransactions,
  ) {
    double income = 0;
    double expenses = 0;
    final Map<String, double> expenseCategoryTotals = {};

    for (final doc in monthTransactions) {
      final data = doc.data();
      final double amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final String type = (data['type'] as String?)?.toLowerCase() ?? '';
      final String category =
          (data['category'] as String?)?.trim().isNotEmpty == true
              ? (data['category'] as String).trim()
              : 'Uncategorized';

      if (type == 'income') {
        income += amount.abs();
      } else if (type == 'expense') {
        final value = amount.abs();
        expenses += value;
        expenseCategoryTotals[category] =
            (expenseCategoryTotals[category] ?? 0) + value;
      } else {
        if (amount >= 0) {
          income += amount;
        } else {
          final value = amount.abs();
          expenses += value;
          expenseCategoryTotals[category] =
              (expenseCategoryTotals[category] ?? 0) + value;
        }
      }
    }

    final double netTotal = income - expenses;
    final double totalExpensesForChart =
        expenseCategoryTotals.values.fold<double>(0, (sum, value) => sum + value);

    if (monthTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 80,
              color: _themeService.primaryBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No analytics data yet",
              style: TextStyle(
                color: _themeService.textSub,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCards(
          income: income,
          expenses: expenses,
          total: netTotal,
        ),
        const SizedBox(height: 20),
        _buildDonutChart(
          expenseTotals: expenseCategoryTotals,
          totalExpenses: totalExpensesForChart,
        ),
        const SizedBox(height: 20),
        _buildCategoryList(
          expenseTotals: expenseCategoryTotals,
          totalExpenses: totalExpensesForChart,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final textColor = _themeService.textMain;
    final monthLabel = DateFormat.yMMMM().format(_selectedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
            size: 18,
          ),
        ),
        Text(
          monthLabel,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: Icon(
            Icons.arrow_forward_ios,
            color: textColor,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards({
    required double income,
    required double expenses,
    required double total,
  }) { 
    final cardColor = _themeService.cardBg;
    final textColor = _themeService.textMain;

    Widget buildCard(String title, double value, Color accent) {
      final isNegative = value < 0;
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
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
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                NumberFormat.currency(symbol: '₱').format(value),
                style: TextStyle(
                  color: isNegative ? Colors.redAccent : accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "This month",
                style: TextStyle(
                  color: _themeService.textSub,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildCard('Income', income, Colors.greenAccent.shade400),
        buildCard('Expenses', -expenses, Colors.redAccent),
        buildCard('Total', total, _themeService.primaryBlue),
      ],
    );
  }

  Widget _buildDonutChart({
    required Map<String, double> expenseTotals,
    required double totalExpenses,
  }) {
    final cardColor = _themeService.cardBg;
    final textColor = _themeService.textMain;
    final List<Color> palette = [
      _themeService.primaryBlue,
      Colors.tealAccent.shade700,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.amber.shade700,
      Colors.deepPurpleAccent,
      Colors.greenAccent.shade400,
      Colors.cyanAccent.shade400,
    ];

    final sections = expenseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sections.isEmpty || totalExpenses == 0) {
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
              "Spending Breakdown",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                "No expense data this month",
                style: TextStyle(color: _themeService.textSub),
              ),
            ),
          ],
        ),
      );
    }

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
            "Spending Breakdown",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 70,
                startDegreeOffset: -90,
                sections: [
                  for (int i = 0; i < sections.length; i++)
                    PieChartSectionData(
                      value: sections[i].value,
                      color: palette[i % palette.length],
                      radius: 70,
                      title:
                          '${(sections[i].value / totalExpenses * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      titlePositionPercentageOffset: 0.6,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (int i = 0; i < sections.length; i++)
                _buildLegendItem(
                  color: palette[i % palette.length],
                  label: sections[i].key,
                  value: sections[i].value,
                  total: totalExpenses,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double value,
    required double total,
  }) {
    final textColor = _themeService.textMain;
    final percent = total == 0 ? 0 : (value / total * 100);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: TextStyle(color: _themeService.textSub),
        ),
      ],
    );
  }

  Widget _buildCategoryList({
    required Map<String, double> expenseTotals,
    required double totalExpenses,
  }) {
    final entries = expenseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final textColor = _themeService.textMain;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
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
            "Categories",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in entries)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailsScreen(
                      categoryName: entry.key,
                      selectedMonth: _selectedMonth,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _themeService.primaryBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value:
                                  totalExpenses == 0 ? 0 : entry.value / totalExpenses,
                              backgroundColor:
                                  _themeService.textSub.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _themeService.primaryBlue,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '₱').format(entry.value),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          totalExpenses == 0
                              ? '0%'
                              : '${(entry.value / totalExpenses * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _themeService.textSub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
