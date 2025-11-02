import 'package:flutter/material.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C2E),
        centerTitle: true,
        title: const Text('Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNetWorthCard(),
          const SizedBox(height: 20),
          const Text("Accounts", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildAccountCards(),
          const SizedBox(height: 20),
          const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildActivityItem("Whole Foods", "₱850.00"),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Net Worth", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("₱0.00", style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text("Across 3 accounts", style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildAccountCards() {
    return Column(
      children: [
        Row(
          children: [
            _accountBox("Cash", "₱0.00", Colors.green, Icons.attach_money),
            const SizedBox(width: 8),
            _accountBox("Bank Account", "₱0.00", Colors.blue, Icons.account_balance),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _accountBox("Savings Account", "₱0.00", Colors.orange, Icons.savings),
            const SizedBox(width: 8),
            Expanded(
              child: DottedBorderBox(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Colors.green),
                      SizedBox(height: 4),
                      Text("Add New Account", style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _accountBox(String title, String balance, Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("Balance $balance", style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String name, String amount) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(amount, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1, style: BorderStyle.solid),
      ),
      child: child,
    );
  }
}
