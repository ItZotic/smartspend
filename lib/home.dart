import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const HomeScreen({super.key, this.scrollController});

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
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          double totalIncome = 0;
          double totalExpense = 0;

          for (final doc in docs) {
            final data = doc.data()! as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            if (amount >= 0) {
              totalIncome += amount;
            } else {
              totalExpense += amount.abs();
            }
          }

          final remainingBalance = totalIncome - totalExpense;

          final todaysRecords = docs.where((d) {
            final data = d.data()! as Map<String, dynamic>;
            final ts = data['createdAt'];
            if (ts is Timestamp) {
              final date = ts.toDate();
              final now = DateTime.now();
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            }
            return false;
          }).toList();

          return Column(
            children: [
              // header
              Container(
                decoration: const BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 48,
                  bottom: 28,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    const Text(
                      'November 2025',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Remaining Balance',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${remainingBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Income\n+₱${totalIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Expenses\n-₱${totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Recent + Daily
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0, bottom: 8),
                      child: Center(
                        child: Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    if (docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No transactions yet.')),
                      ),
                    ...docs.map((d) {
                      final data = d.data()! as Map<String, dynamic>;
                      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                      final isExpense = amount < 0;
                      final ts = data['createdAt'];
                      final time =
                          ts is Timestamp ? ts.toDate() : DateTime.now();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            child: Icon(
                              isExpense
                                  ? Icons.shopping_bag_outlined
                                  : Icons.attach_money,
                              color:
                                  isExpense ? Colors.redAccent : Colors.green,
                            ),
                          ),
                          title: Text(
                            data['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${data['category'] ?? ''} • ${TimeOfDay.fromDateTime(time).format(context)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.green,
                                    ),
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
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
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
                                              onPressed: () => Navigator.pop(
                                                ctx,
                                                false,
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                ctx,
                                                true,
                                              ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
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
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Daily Records',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF1A1A2E),
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
                            final data = d.data()! as Map<String, dynamic>;
                            final amount =
                                (data['amount'] as num?)?.toDouble() ?? 0;
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
                                            ? Icons.remove_circle_outline
                                            : Icons.add_circle_outline,
                                        color: isExpense
                                            ? Colors.redAccent
                                            : Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              data['category'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
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
              if (!mounted) {
                return;
              }
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
