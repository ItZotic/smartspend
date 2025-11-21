import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DailyRecordsScreen extends StatelessWidget {
  const DailyRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final stream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Daily Records',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No records found.'));
          }

          final docs = snap.data!.docs;

          // Group by date
          final Map<String, List<QueryDocumentSnapshot>> groups = {};
          for (final d in docs) {
            final data = d.data()! as Map<String, dynamic>;
            final ts = data['createdAt'];
            DateTime dt = DateTime.now();
            if (ts is Timestamp) {
              dt = ts.toDate();
            }
            final key = DateFormat.yMMMMd().format(dt);
            groups.putIfAbsent(key, () => []).add(d);
          }

          final keys = groups.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: keys.length,
            itemBuilder: (context, idx) {
              final day = keys[idx];
              final items = groups[day]!;
              double dayTotal = 0;
              for (final item in items) {
                final ddata = item.data()! as Map<String, dynamic>;
                dayTotal += ((ddata['amount'] as num?)?.toDouble() ?? 0);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // day header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₱${dayTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: dayTotal >= 0
                              ? Colors.green
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: items.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final ts = data['createdAt'];
                      final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
                      final formattedTime = DateFormat.jm().format(dt);
                      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                      final isExpense = amount < 0;
                      return Dismissible(
                        key: Key(doc.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const FaIcon(
                            FontAwesomeIcons.trash,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          final messenger = ScaffoldMessenger.of(context);
                          await FirebaseFirestore.instance
                              .collection('transactions')
                              .doc(doc.id)
                              .delete();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Transaction deleted'),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[100],
                                child: Icon(
                                  isExpense
                                      ? Icons.shopping_cart_outlined
                                      : Icons.trending_up,
                                  color: isExpense
                                      ? Colors.redAccent
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${data['category'] ?? ''} • $formattedTime',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isExpense ? '-' : '+'}₱${amount.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isExpense
                                          ? Colors.redAccent
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const FaIcon(
                                          FontAwesomeIcons.pen,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (_) =>
                                                EditTransactionSheet(
                                                  docId: doc.id,
                                                  data: data,
                                                ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const FaIcon(
                                          FontAwesomeIcons.trash,
                                          size: 16,
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
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
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
                                                .doc(doc.id)
                                                .delete();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// A small edit sheet reused here
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
              if (!context.mounted) return;
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
