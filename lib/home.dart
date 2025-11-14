import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum ViewMode { daily, monthly }

class HomeScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const HomeScreen({super.key, this.scrollController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewMode _viewMode = ViewMode.monthly;
  late int _selectedMonth;
  late int _selectedYear;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _selectedDay = DateTime(now.year, now.month, now.day);
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

          final allDocs = snapshot.data?.docs ?? [];
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final date = _extractDate(data['date'] ?? data['createdAt']);
            if (date == null) return false;
            if (_viewMode == ViewMode.daily) {
              return date.year == _selectedDay.year &&
                  date.month == _selectedDay.month &&
                  date.day == _selectedDay.day;
            } else {
              return date.year == _selectedYear &&
                  date.month == _selectedMonth;
            }
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
            final date = _extractDate(data['date'] ?? data['createdAt']);
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              '${_monthName(_selectedMonth)}  •  $_selectedYear',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                            final time =
                                _extractDate(data['date'] ?? data['createdAt']) ??
                                    DateTime.now();

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
    setState(() {
      final updated = DateTime(_selectedYear, _selectedMonth + delta, 1);
      _selectedMonth = updated.month;
      _selectedYear = updated.year;
      _syncSelectedDayWithMonth();
    });
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: delta));
      _selectedMonth = _selectedDay.month;
      _selectedYear = _selectedDay.year;
    });
  }

  void _changeViewMode(ViewMode mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      if (mode == ViewMode.monthly) {
        _selectedMonth = _selectedDay.month;
        _selectedYear = _selectedDay.year;
      } else {
        _syncSelectedDayWithMonth();
      }
    });
  }

  void _syncSelectedDayWithMonth() {
    var day = _selectedDay.day;
    final maxDay = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    if (day > maxDay) day = maxDay;
    if (day < 1) day = 1;
    _selectedDay = DateTime(_selectedYear, _selectedMonth, day);
  }

  void _showDisplayOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'View Mode',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _viewModeButton(
                            label: 'Daily',
                            selected: _viewMode == ViewMode.daily,
                            onTap: () {
                              _changeViewMode(ViewMode.daily);
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _viewModeButton(
                            label: 'Monthly',
                            selected: _viewMode == ViewMode.monthly,
                            onTap: () {
                              _changeViewMode(ViewMode.monthly);
                              setModalState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _viewMode == ViewMode.daily
                          ? 'Selected Day'
                          : 'Selected Month',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_viewMode == ViewMode.daily) {
                              _changeDay(-1);
                            } else {
                              _changeMonth(-1);
                            }
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _viewMode == ViewMode.daily
                                  ? DateFormat('MMM d, yyyy')
                                      .format(_selectedDay)
                                  : '${_monthName(_selectedMonth)} $_selectedYear',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_viewMode == ViewMode.daily) {
                              _changeDay(1);
                            } else {
                              _changeMonth(1);
                            }
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget _viewModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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

class TransactionSearchDelegate extends SearchDelegate<void> {
  final List<QueryDocumentSnapshot> allDocs;

  TransactionSearchDelegate(this.allDocs);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final matches = _filterDocs();
    if (matches.isEmpty) {
      return const Center(
        child: Text('No matching records found.'),
      );
    }
    return _buildList(matches);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Search by note, category, or account name.'),
      );
    }
    final matches = _filterDocs();
    if (matches.isEmpty) {
      return const Center(
        child: Text('No matching records found.'),
      );
    }
    return _buildList(matches);
  }

  List<QueryDocumentSnapshot> _filterDocs() {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return [];
    return allDocs.where((doc) {
      final data = doc.data()! as Map<String, dynamic>;
      final note = (data['note'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final account = (data['accountName'] ?? '').toString().toLowerCase();
      return note.contains(keyword) ||
          category.contains(keyword) ||
          account.contains(keyword);
    }).toList();
  }

  Widget _buildList(List<QueryDocumentSnapshot> matches) {
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final data = matches[index].data()! as Map<String, dynamic>;
        final note = (data['note'] ?? '').toString();
        final category = (data['category'] ?? '').toString();
        final accountName = (data['accountName'] ?? '').toString();
        return ListTile(
          title: Text(note),
          subtitle: Text('$category  •  $accountName'),
        );
      },
    );
  }
}
