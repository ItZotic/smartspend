import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:smartspend/services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onAddTransaction, FirestoreService? firestoreService})
      : _firestoreService = firestoreService;

  final VoidCallback? onAddTransaction;
  final FirestoreService? _firestoreService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Top Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month and Calendar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "October 2025",
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.calendar_today, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),

                // Total Balance
                const Center(
                  child: Column(
                    children: [
                      Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      SizedBox(height: 5),
                      Text(
                        "₱0.00",
                        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Income / Expenses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Income\n+₱25,000.00",
                        style: TextStyle(color: Colors.greenAccent, fontSize: 16, height: 1.5)),
                    Text("Expenses\n-₱1,300.50",
                        style: TextStyle(color: Colors.redAccent, fontSize: 16, height: 1.5)),
                  ],
                ),
              ],
            ),
          ),

          // Recent Transactions
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Recent Transactions",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("View All", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  _transactionItem(
                    icon: Icons.local_grocery_store,
                    title: "Whole Foods",
                    category: "Food & Dining",
                    amount: "-₱850.00",
                    amountColor: Colors.red,
                    time: "2:30 PM",
                    date: "Today",
                  ),
                  _transactionItem(
                    icon: Icons.account_balance,
                    title: "Tech Corp",
                    category: "Salary",
                    amount: "+₱25,000.00",
                    amountColor: Colors.green,
                    time: "8:00 AM",
                    date: "Yesterday",
                  ),
                  _transactionItem(
                    icon: Icons.local_gas_station,
                    title: "Gas Station",
                    category: "Transportation",
                    amount: "-₱450.50",
                    amountColor: Colors.red,
                    time: "6:45 PM",
                    date: "Oct 23",
                  ),
                  _buildTransactionsList(),
                ],
              ),
            ),
          ),

          // Floating Add Button
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: onAddTransaction ?? () {},
              child: const Icon(Icons.add, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    final service = _firestoreService ?? FirestoreService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.streamTransactions(uid: uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            final type = data['type'] as String? ?? '';
            final note = (data['note'] as String?)?.trim() ?? '';
            final timestamp = data['date'];
            DateTime? transactionDate;
            if (timestamp is Timestamp) {
              transactionDate = timestamp.toDate();
            }

            return ListTile(
              dense: true,
              title: Text('$type  •  ${amount.toStringAsFixed(2)}'),
              subtitle: Text(
                note.isEmpty
                    ? '${transactionDate ?? ''}'
                    : '$note  •  ${transactionDate ?? ''}',
              ),
              contentPadding: EdgeInsets.zero,
            );
          },
        );
      },
    );
  }

  static Widget _transactionItem({
    required IconData icon,
    required String title,
    required String category,
    required String amount,
    required Color amountColor,
    required String time,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 5, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 35),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(category, style: const TextStyle(color: Colors.grey)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount,
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 15)),
            Text("$time • $date", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}
