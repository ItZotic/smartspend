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

  DateTime get _monthStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _nextMonthStart =>
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
                    child: Text(
                      "Analytics",
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMonthSelector(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _user == null
                        ? Center(
                            child: Text(
                              'Please log in to view analytics.',
                              style: TextStyle(color: _themeService.textSub),
                            ),
                          )
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _firestoreService
                                .streamTransactions(uid: _user.uid),
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

                              double income = 0;
                              double expenses = 0;
                              final Map<String, double> expenseByCategory = {};

                              for (final doc in monthTransactions) {
                                final data = doc.data();
                                final double amount =
                                    (data['amount'] as num?)?.toDouble() ?? 0;
                                final String category =
                                    (data['category'] as String?)
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? (data['category'] as String).trim()
                                        : 'Uncategorized';
                                final type =
                                    (data['type'] as String?)?.toLowerCase();

                                final isExpense =
                                    type == 'expense' || amount < 0;
                                final isIncome =
                                    type == 'income' || (amount >= 0 && !isExpense);

                                if (isIncome) {
                                  income += amount.abs();
                                }

                                if (isExpense) {
                                  final expenseValue = amount.abs();
                                  expenses += expenseValue;
                                  expenseByCategory[category] =
                                      (expenseByCategory[category] ?? 0) +
                                          expenseValue;
                                }
                              }

                              final double netTotal = income - expenses;

                              final bodyChildren = <Widget>[
                                _buildSummaryCards(
                                  income: income,
                                  expenses: expenses,
                                  total: netTotal,
                                ),
                                const SizedBox(height: 16),
                                _buildDonutChart(
                                  categoryTotals: expenseByCategory,
                                  total: expenses,
                                ),
                                const SizedBox(height: 16),
                                _buildCategoryList(
                                  categoryTotals: expenseByCategory,
                                  totalExpenses: expenses,
                                ),
                              ];

                              return SingleChildScrollView(
                                controller: widget.scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: monthTransactions.isEmpty
                                      ? [
                                          _buildEmptyState(),
                                        ]
                                      : bodyChildren,
                                ),
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

    Widget buildCard(String title, double value, Color accent, IconData icon) {
      final isNegative = value < 0;

      return Container(
        // ❌ no horizontal margin here anymore
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Amount – will shrink a bit instead of overflowing if very long
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _formatCurrency(value),
                style: TextStyle(
                  color: isNegative ? Colors.redAccent : accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "This month",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _themeService.textSub,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: buildCard(
            'Income',
            income,
            Colors.greenAccent.shade400,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: buildCard(
            'Expenses',
            -expenses,
            Colors.redAccent,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: buildCard(
            'Total',
            total,
            total >= 0 ? _themeService.primaryBlue : Colors.redAccent,
            Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  List<Color> get _chartColors => [
        _themeService.primaryBlue,
        Colors.tealAccent.shade700,
        Colors.orangeAccent,
        Colors.pinkAccent,
        Colors.amber.shade700,
        Colors.deepPurpleAccent,
        Colors.greenAccent.shade400,
        Colors.cyanAccent.shade400,
        Colors.indigoAccent,
        Colors.lightGreenAccent.shade700,
      ];

  Widget _buildDonutChart({
    required Map<String, double> categoryTotals,
    required double total,
  }) {
    final cardColor = _themeService.cardBg;
    final textColor = _themeService.textMain;
    final palette = _chartColors;
    final sections = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Spending Breakdown",
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _themeService.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Expenses only',
                  style: TextStyle(
                    color: _themeService.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (total <= 0)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No expenses recorded for this month',
                  style: TextStyle(color: _themeService.textSub),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 170,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      sections: [
                        for (int i = 0; i < sections.length; i++)
                          PieChartSectionData(
                            value: sections[i].value,
                            color: palette[i % palette.length],
                            radius: 55,
                            title: total == 0
                                ? ''
                                : '${(sections[i].value / total * 100).toStringAsFixed(0)}%',
                            titleStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                      centerSpaceColor: cardColor,
                      centerSpaceRadius: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Total expenses: ${_formatCurrency(total)}",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                  total: total,
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
    required Map<String, double> categoryTotals,
    required double totalExpenses,
  }) {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final textColor = _themeService.textMain;
    final palette = _chartColors;

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
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No expenses recorded for this month',
                style: TextStyle(color: _themeService.textSub),
              ),
            )
          else
            for (int i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openCategoryDetails(entries[i].key),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length].withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: palette[i % palette.length],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entries[i].key,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: totalExpenses == 0
                                    ? 0
                                    : entries[i].value / totalExpenses,
                                backgroundColor:
                                    _themeService.textSub.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette[i % palette.length],
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
                            _formatCurrency(entries[i].value),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            totalExpenses == 0
                                ? '0%'
                                : '${(entries[i].value / totalExpenses * 100).toStringAsFixed(1)}%',
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 72,
            color: _themeService.primaryBlue.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
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

  void _openCategoryDetails(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailsScreen(
          categoryName: category,
          selectedMonth: _selectedMonth,
        ),
      ),
    );
  }
}
