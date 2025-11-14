import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const HomeScreen({super.key, this.scrollController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedMonth;
  late int _selectedYear;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _rangeStart = DateTime(_selectedYear, _selectedMonth);
    _rangeEnd = DateTime(_selectedYear, _selectedMonth + 1);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1A1A2E);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final transactionsStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final filteredDocs = docs.where((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final date = _extractDate(data['createdAt']);
            if (date == null) return false;
            return !date.isBefore(_rangeStart) && date.isBefore(_rangeEnd);
          }).toList();

          double totalIncome = 0;
          double totalExpense = 0;

          for (final doc in filteredDocs) {
            final data = doc.data()! as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            if (amount >= 0) {
              totalIncome += amount;
            } else {
              totalExpense += amount.abs();
            }
          }

          final remainingBalance = totalIncome - totalExpense;

          final todaysRecords = filteredDocs.where((d) {
            final data = d.data()! as Map<String, dynamic>;
            final date = _extractDate(data['createdAt']);
            if (date == null) return false;
            final now = DateTime.now();
            return date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          }).toList();

          return Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 40,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: () => _changeMonth(-1),
                        ),
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _showMonthPicker,
                                  child: Row(
                                    children: [
                                      Text(
                                        _monthName(_selectedMonth),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: _showYearPicker,
                                  child: Row(
                                    children: [
                                      Text(
                                        '$_selectedYear',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: () => _changeMonth(1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.dehaze, color: Colors.white),
                          onPressed: () => _showDisplayOptionsSheet(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _summaryItem(
                          label: 'EXPENSE',
                          value: '-₱${totalExpense.toStringAsFixed(2)}',
                          valueColor: Colors.redAccent,
                        ),
                        _summaryItem(
                          label: 'INCOME',
                          value: '+₱${totalIncome.toStringAsFixed(2)}',
                          valueColor: Colors.greenAccent,
                        ),
                        _summaryItem(
                          label: 'TOTAL',
                          value: '₱${remainingBalance.toStringAsFixed(2)}',
                          valueColor: remainingBalance >= 0
                              ? Colors.white
                              : Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Recent + Daily
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(child: Text('No transactions yet.'))
                    : ListView(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          ...filteredDocs.map((d) {
                            final data = d.data()! as Map<String, dynamic>;
                            final amount =
                                (data['amount'] as num?)?.toDouble() ?? 0;
                            final isExpense = amount < 0;
                            final time = _extractDate(data['createdAt']) ?? DateTime.now();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Leading icon
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[100],
                                    child: Icon(
                                      isExpense
                                          ? Icons.shopping_bag_outlined
                                          : Icons.attach_money,
                                      color: isExpense
                                          ? Colors.redAccent
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Title + subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          data['name'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${data['category'] ?? ''} • ${TimeOfDay.fromDateTime(time).format(context)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // MIDDLE: edit/delete (center aligned vertically)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _miniIconButton(
                                        icon: Icons.edit,
                                        color: Colors.green,
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) => EditTransactionSheet(
                                              docId: d.id,
                                              data: data,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      _miniIconButton(
                                        icon: Icons.delete,
                                        color: Colors.redAccent,
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Delete Transaction?',
                                              ),
                                              content: const Text(
                                                'This action cannot be undone.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          ctx, true),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.redAccent),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('transactions')
                                                .doc(d.id)
                                                .delete();
                                          }
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 8),

                                  // RIGHT: amount (hard width + FittedBox => never overflows)
                                  SizedBox(
                                    width: 96, // clamp width to keep layout stable
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${isExpense ? '-' : '+'}₱${amount.abs().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: isExpense
                                              ? Colors.redAccent
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 20),

                          // Daily Records card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today’s Records',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (todaysRecords.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'No records for today.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ...todaysRecords.map((d) {
                                  final data =
                                      d.data()! as Map<String, dynamic>;
                                  final amount = (data['amount'] as num?)
                                          ?.toDouble() ??
                                      0;
                                  final isExpense = amount < 0;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isExpense
                                                  ? Icons
                                                      .remove_circle_outline
                                                  : Icons.add_circle_outline,
                                              color: isExpense
                                                  ? Colors.redAccent
                                                  : Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  data['name'] ?? '',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  data['category'] ?? '',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '${isExpense ? '-' : '+'}₱${amount.abs().toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: isExpense
                                                  ? Colors.redAccent
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
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

  void _changeMonth(int delta) {
    final updated = DateTime(_selectedYear, _selectedMonth + delta);
    _reloadTransactionsForSelectedPeriod(
      month: updated.month,
      year: updated.year,
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView.builder(
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = month == _selectedMonth;
              return ListTile(
                title: Text(
                  _monthName(month),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _reloadTransactionsForSelectedPeriod(month: month);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showYearPicker() {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 10;
    final endYear = currentYear + 10;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView.builder(
            itemCount: endYear - startYear + 1,
            itemBuilder: (context, index) {
              final year = startYear + index;
              final isSelected = year == _selectedYear;
              return ListTile(
                title: Text(
                  '$year',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _reloadTransactionsForSelectedPeriod(year: year);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _reloadTransactionsForSelectedPeriod({int? month, int? year}) {
    setState(() {
      if (month != null) _selectedMonth = month;
      if (year != null) _selectedYear = year;
      _rangeStart = DateTime(_selectedYear, _selectedMonth);
      _rangeEnd = DateTime(_selectedYear, _selectedMonth + 1);
    });
  }

  String _monthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }

  DateTime? _extractDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  // Tiny icon button used in the middle column
  Widget _miniIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      splashRadius: 18,
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showDisplayOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Center(
                  child: Text(
                    'Display Option',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'View mode:',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text('✓ DAILY', style: TextStyle(color: Colors.white)),
                SizedBox(height: 4),
                Text('WEEKLY', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 4),
                Text('MONTHLY', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 16),
                Text(
                  'Show total:',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text('✓ YES', style: TextStyle(color: Colors.white)),
                SizedBox(height: 4),
                Text('NO', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// EditTransactionSheet unchanged except UI later (we'll keep this simple for now)
class EditTransactionSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditTransactionSheet({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController amountCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.data['name'] ?? '');
    categoryCtrl = TextEditingController(text: widget.data['category'] ?? '');
    amountCtrl = TextEditingController(text: widget.data['amount'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Wrap(
        children: [
          const Center(
            child: Text(
              'Edit Transaction',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: categoryCtrl,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: amountCtrl,
            decoration: const InputDecoration(
              labelText: 'Amount (₱)',
              prefixText: '₱',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              await FirebaseFirestore.instance
                  .collection('transactions')
                  .doc(widget.docId)
                  .update({
                'name': nameCtrl.text,
                'category': categoryCtrl.text,
                'amount': amount,
              });
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              'Save Changes',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}