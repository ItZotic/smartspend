import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspend/services/theme_service.dart';

class BudgetScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const BudgetScreen({super.key, this.scrollController});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final ThemeService _themeService = ThemeService();

  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  final List<String> _allExpenseCategories = [
    'Food & Dining',
    'Transportation',
    'Bills',
    'Groceries',
    'Entertainment',
    'Shopping',
    'Healthcare',
    'Education',
    'Travel',
    'Utilities',
  ];

  final Set<String> _budgetedCategories = {};
  final Map<String, double> _budgetLimits = {};
  final Map<String, double> _spentAmounts = {};

  DateTime get _monthStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _nextMonthStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

  String get _monthLabel => DateFormat.yMMMM().format(_selectedMonth);

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

  double get _totalBudget =>
      _budgetLimits.values.fold(0.0, (sum, value) => sum + value);

  double get _totalSpent =>
      _spentAmounts.values.fold(0.0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        if (user == null) {
          return const Center(
            child: Text("Please log in to view your budget."),
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
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Center(
                      child: Text(
                        "Budgets",
                        style: TextStyle(
                          color: _themeService.textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [
                        _buildMonthSelector(),
                        const SizedBox(height: 16),
                        _buildBudgetSummaryCard(
                          totalBudget: _totalBudget,
                          totalSpent: _totalSpent,
                        ),
                        const SizedBox(height: 24),
                        _buildBudgetedSection(),
                        const SizedBox(height: 24),
                        _buildNotBudgetedSection(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: _themeService.primaryBlue,
            onPressed: () {
              // TODO: open add budget screen
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _themeService.textMain.withValues(alpha: 0.7),
            size: 18,
          ),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          _monthLabel,
          style: TextStyle(
            color: _themeService.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            color: _themeService.textMain.withValues(alpha: 0.7),
            size: 18,
          ),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }


  Widget _buildBudgetSummaryCard({
    required double totalBudget,
    required double totalSpent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _themeService.isDarkMode ? 0.3 : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOTAL BUDGET",
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _themeService.formatCurrency(totalBudget),
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 56,
            color: _themeService.textSub.withValues(alpha: 0.2),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "TOTAL SPENT",
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _themeService.formatCurrency(totalSpent),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetedSection() {
    final budgeted =
        _allExpenseCategories.where(_budgetedCategories.contains).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Budgeted categories: $_monthLabel",
          style: TextStyle(
            color: _themeService.textMain,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (budgeted.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _themeService.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              "Currently, no budget is applied for this month. Set budget limits for this month, or copy your budget limits from previous months.",
              style: TextStyle(
                color: _themeService.textSub,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          )
        else
          Column(
            children: budgeted
                .map(
                  (category) => _buildBudgetedRow(
                    category,
                    _budgetLimits[category] ?? 0,
                    _spentAmounts[category] ?? 0,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildBudgetedRow(
    String category,
    double budgetAmount,
    double spentAmount,
  ) {
    final progress = budgetAmount == 0
        ? 0.0
        : (spentAmount / budgetAmount).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _themeService.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_rounded,
              color: _themeService.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        _themeService.primaryBlue.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _themeService.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Spent ${_themeService.formatCurrency(spentAmount)} of ${_themeService.formatCurrency(budgetAmount)}",
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _themeService.textMain,
              side: BorderSide(
                color: _themeService.textSub.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // TODO: open budget editor
            },
            child: const Text(
              "EDIT",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotBudgetedSection() {
    final notBudgeted =
        _allExpenseCategories.where((c) => !_budgetedCategories.contains(c));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Not budgeted this month",
          style: TextStyle(
            color: _themeService.textMain,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (notBudgeted.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _themeService.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              "All categories have budgets this month.",
              style: TextStyle(
                color: _themeService.textSub,
                fontSize: 14,
              ),
            ),
          )
        else
          Column(
            children: notBudgeted
                .map((category) => _buildNotBudgetedRow(category))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildNotBudgetedRow(String category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _themeService.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_rounded,
              color: _themeService.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              category,
              style: TextStyle(
                color: _themeService.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _themeService.textMain,
              side: BorderSide(
                color: _themeService.textSub.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // TODO: open budget editor
            },
            child: const Text(
              "SET BUDGET",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
