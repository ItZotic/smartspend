import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspend/models/category_icon_option.dart';
import 'package:smartspend/services/firestore_service.dart';
import 'package:smartspend/services/theme_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const BudgetScreen({super.key, this.scrollController});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService = FirestoreService();
  final ThemeService _themeService = ThemeService();

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  final Set<String> _budgetedCategories = {};
  final Map<String, double> _budgetLimits = {};
  final Map<String, double> _spentAmounts = {};
  Map<String, Map<String, dynamic>> _expenseCategoryMeta = {};

  String get _monthLabel => DateFormat.yMMMM().format(_selectedMonth);

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  double get _totalBudget =>
      _budgetLimits.values.fold(0.0, (sum, value) => sum + value);

  double get _totalSpent =>
      _spentAmounts.values.fold(0.0, (sum, value) => sum + value);

  Map<String, dynamic> _getCategoryMeta(String categoryName) {
    return _expenseCategoryMeta[categoryName] ?? {};
  }

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

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.streamCategoriesByType(
            uid: user!.uid,
            type: 'expense',
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: _themeService.primaryBlue,
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final expenseCategoryMeta = <String, Map<String, dynamic>>{};

            final expenseCategories = docs
                .map((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String?)?.trim();
                  if (name != null && name.isNotEmpty) {
                    expenseCategoryMeta[name] = data;
                  }
                  return name;
                })
                .whereType<String>()
                .where((name) => name.isNotEmpty)
                .toList();

            _expenseCategoryMeta = expenseCategoryMeta;

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
                            _buildBudgetedSection(expenseCategories),
                            const SizedBox(height: 24),
                            _buildNotBudgetedSection(expenseCategories),
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
                  if (expenseCategories.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Add an expense category first to set a budget.',
                          style: TextStyle(color: _themeService.textMain),
                        ),
                        backgroundColor: _themeService.cardBg,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _showAddBudgetDialog(expenseCategories);
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            );
          },
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

  Widget _buildBudgetedSection(List<String> allCategories) {
    if (allCategories.isEmpty) {
      return Container(
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
          "Add an expense category to start budgeting.",
          style: TextStyle(color: _themeService.textSub, fontSize: 14),
        ),
      );
    }

    final budgeted = allCategories.where(_budgetedCategories.contains).toList();

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
    final categoryData = _getCategoryMeta(category);
    final iconOption = getCategoryIconOptionFromData(categoryData);
    final iconColor = getCategoryIconBgColor(categoryData);

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
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconOption.icon,
              color: iconColor,
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
                    backgroundColor: _themeService.primaryBlue.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _themeService.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Spent ${_themeService.formatCurrency(spentAmount)} of ${_themeService.formatCurrency(budgetAmount)}",
                  style: TextStyle(color: _themeService.textSub, fontSize: 13),
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
            onPressed: () => _showSetBudgetDialog(category),
            child: const Text(
              "EDIT",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotBudgetedSection(List<String> allCategories) {
    if (allCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final notBudgeted = allCategories.where(
      (c) => !_budgetedCategories.contains(c),
    );

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
              style: TextStyle(color: _themeService.textSub, fontSize: 14),
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
    final categoryData = _getCategoryMeta(category);
    final iconOption = getCategoryIconOptionFromData(categoryData);
    final iconColor = getCategoryIconBgColor(categoryData);

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
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconOption.icon,
              color: iconColor,
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
            onPressed: () => _showSetBudgetDialog(category),
            child: const Text(
              "SET BUDGET",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetBudgetDialog(String categoryName) async {
    final TextEditingController limitController = TextEditingController(
      text: _budgetLimits[categoryName]?.toString() ?? '',
    );

    final categoryData = _getCategoryMeta(categoryName);
    final iconOption = getCategoryIconOptionFromData(categoryData);
    final iconColor = getCategoryIconBgColor(categoryData);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: _themeService.cardBg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Set budget',
                    style: TextStyle(
                      color: _themeService.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _themeService.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _themeService.textSub.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(
                            alpha: 0.15,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconOption.icon,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: _themeService.textMain,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Limit',
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    filled: true,
                    fillColor: _themeService.cardBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _themeService.textSub.withValues(alpha: 0.25),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _themeService.primaryBlue),
                    ),
                  ),
                  style: TextStyle(color: _themeService.textMain),
                ),
                const SizedBox(height: 12),
                Text(
                  'Month: $_monthLabel',
                  style: TextStyle(
                    color: _themeService.textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _themeService.textMain,
                          side: BorderSide(
                            color: _themeService.textSub.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _themeService.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final entered = double.tryParse(
                            limitController.text.trim(),
                          );
                          final currentUser = user;

                          if (entered == null || currentUser == null) {
                            Navigator.of(context).pop();
                            return;
                          }

                          setState(() {
                            _budgetedCategories.add(categoryName);
                            _budgetLimits[categoryName] = entered;
                            _spentAmounts.putIfAbsent(categoryName, () => 0);
                          });

                          await _firestoreService.setBudgetLimit(
                            uid: currentUser.uid,
                            categoryName: categoryName,
                            month: _selectedMonth,
                            limit: entered,
                          );

                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'SET',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddBudgetDialog(List<String> categories) async {
    if (categories.isEmpty) return;

    String selectedCategory = categories.firstWhere(
      (c) => !_budgetedCategories.contains(c),
      orElse: () => categories.first,
    );
    final TextEditingController limitController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: _themeService.cardBg,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Add budget',
                        style: TextStyle(
                          color: _themeService.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: _themeService.cardBg,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _themeService.cardBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.textSub.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.primaryBlue,
                          ),
                        ),
                      ),
                      iconEnabledColor: _themeService.textMain,
                      items: categories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(color: _themeService.textMain),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Limit',
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: limitController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        filled: true,
                        fillColor: _themeService.cardBg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.textSub.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _themeService.primaryBlue,
                          ),
                        ),
                      ),
                      style: TextStyle(color: _themeService.textMain),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _themeService.textMain,
                              side: BorderSide(
                                color: _themeService.textSub.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _themeService.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final enteredLimit = double.tryParse(
                                limitController.text.trim(),
                              );
                              final currentUser = user;

                              if (enteredLimit == null || currentUser == null) {
                                Navigator.of(context).pop();
                                return;
                              }

                              setState(() {
                                _budgetedCategories.add(selectedCategory);
                                _budgetLimits[selectedCategory] = enteredLimit;
                                _spentAmounts.putIfAbsent(
                                  selectedCategory,
                                  () => 0,
                                );
                              });

                              await _firestoreService.setBudgetLimit(
                                uid: currentUser.uid,
                                categoryName: selectedCategory,
                                month: _selectedMonth,
                                limit: enteredLimit,
                              );

                              if (!mounted) return;
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'SAVE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
