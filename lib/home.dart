import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:smartspend/services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onAddTransaction,
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService;

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
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "October 2025",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      Text(
                        "Total Balance",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "₱0.00",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Income\n+₱25,000.00",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      "Expenses\n-₱1,300.50",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Recent Transactions
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: _buildTransactionsList(),
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
    if (uid == null) return const Center(child: Text("Please log in"));

    final service = _firestoreService ?? FirestoreService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.streamTransactions(uid: uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No transactions yet"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            final type = data['type'] as String? ?? '';
            final note = (data['note'] as String?)?.trim() ?? '';
            final timestamp = data['date'];
            DateTime? transactionDate;
            if (timestamp is Timestamp) transactionDate = timestamp.toDate();

            return ListTile(
              title: Text('$type • ${amount.toStringAsFixed(2)}'),
              subtitle: Text(
                note.isEmpty
                    ? '${transactionDate ?? ''}'
                    : '$note • ${transactionDate ?? ''}',
              ),
            );
          },
        );
      },
    );
  }
}
