import 'package:flutter/material.dart';
import 'package:smartspend/services/theme_service.dart';

class AccountsScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const AccountsScreen({super.key, this.scrollController});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final ThemeService _themeService = ThemeService();

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
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      "Accounts",
                      style: TextStyle(
                        color: _themeService.textMain,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Pass doubles here, NOT strings with symbols!
                        _buildAccountCard(
                          "Cash",
                          5000.00, // Pass double
                          Icons.money,
                        ),
                        const SizedBox(height: 16),
                        _buildAccountCard(
                          "Bank",
                          50000.00, // Pass double
                          Icons.account_balance,
                        ),
                        const SizedBox(height: 16),
                        _buildAccountCard(
                          "Credit Card",
                          -2500.00, // Pass double
                          Icons.credit_card,
                        ),
                        const SizedBox(height: 100),
                      ],
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

  Widget _buildAccountCard(String name, double balance, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _themeService.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              _themeService.isDarkMode ? 0.3 : 0.05,
            ),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _themeService.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _themeService.primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _themeService.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available Balance",
                  style: TextStyle(color: _themeService.textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          // Format the double using the service!
          Text(
            _themeService.formatCurrency(balance),
            style: TextStyle(
              color: _themeService.textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
