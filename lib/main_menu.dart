import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'home.dart';
import 'budget.dart';
import 'analytics.dart';
import 'accounts.dart';
import 'settings.dart';
import 'services/auth_service.dart';
import 'add_transaction.dart'; // opens add transaction screen/modal

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  late final ScrollController _homeScrollController;
  late final ScrollController _budgetScrollController;
  late final ScrollController _analyticsScrollController;
  late final ScrollController _accountsScrollController;
  late final List<Widget> _pages;
  bool _fabVisible = true;
  final Map<ScrollController, VoidCallback> _controllerListeners = {};

  // pages for bottom nav
  void _handleScroll(ScrollController controller) {
    if (!controller.hasClients) {
      return;
    }
    final direction = controller.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (direction == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
  }

  void _registerController(ScrollController controller) {
    void listener() => _handleScroll(controller);
    controller.addListener(listener);
    _controllerListeners[controller] = listener;
  }

  @override
  void initState() {
    super.initState();
    _homeScrollController = ScrollController();
    _budgetScrollController = ScrollController();
    _analyticsScrollController = ScrollController();
    _accountsScrollController = ScrollController();

    for (final controller in [
      _homeScrollController,
      _budgetScrollController,
      _analyticsScrollController,
      _accountsScrollController,
    ]) {
      _registerController(controller);
    }
    _pages = [
      HomeScreen(scrollController: _homeScrollController),
      BudgetScreen(scrollController: _budgetScrollController),
      AnalyticsScreen(scrollController: _analyticsScrollController),
      AccountsScreen(scrollController: _accountsScrollController),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _controllerListeners.forEach((controller, listener) {
      controller
        ..removeListener(listener)
        ..dispose();
    });
    _controllerListeners.clear();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (!_fabVisible) {
        _fabVisible = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D1B2A); // navy
    const Color backgroundColor = Color(0xFFF5F6FA);
    const Color inactiveColor = Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'SmartSpend',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (!context.mounted) {
                return;
              }
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),

      // Floating + opens add transaction as full-screen modal
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        offset: _fabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _fabVisible ? 1 : 0,
          child: FloatingActionButton(
            backgroundColor: primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // open full-screen add transaction page (modal route)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: inactiveColor,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
