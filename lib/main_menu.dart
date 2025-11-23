import 'package:flutter/material.dart';
import 'package:smartspend/services/theme_service.dart'; // Import Theme Service
import 'home.dart';
import 'budget.dart';
import 'analytics.dart';
import 'accounts.dart';
import 'categories_screen.dart';
import 'package:smartspend/widgets/add_transaction.dart';
import 'package:flutter/rendering.dart'; // <-- REQUIRED for ScrollDirection

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final ThemeService _themeService = ThemeService();

  int _selectedIndex = 0;
  // Controllers
  late final ScrollController _homeScrollController;
  late final ScrollController _budgetScrollController;
  late final ScrollController _analyticsScrollController;
  late final ScrollController _accountsScrollController;

  late final List<Widget> _pages;
  bool _fabVisible = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Reset FAB visibility when switching tabs
      _fabVisible = true;
    });
  }

  // ... (Scroll listener logic - keep existing if you want scroll-to-hide) ...
  // Simplification for clarity:
  void _handleScroll(ScrollController controller) {
    if (!controller.hasClients) return;
    final direction = controller.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (direction == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
  }

  void _registerController(ScrollController controller) {
    controller.addListener(() => _handleScroll(controller));
  }

  @override
  void initState() {
    super.initState();
    _homeScrollController = ScrollController();
    _budgetScrollController = ScrollController();
    _analyticsScrollController = ScrollController();
    _accountsScrollController = ScrollController();

    // Register listeners for scroll-to-hide behavior
    _registerController(_homeScrollController);
    // ... register others if needed

    _pages = [
      HomeScreen(scrollController: _homeScrollController),
      BudgetScreen(scrollController: _budgetScrollController),
      AnalyticsScreen(scrollController: _analyticsScrollController),
      AccountsScreen(scrollController: _accountsScrollController),
      const CategoriesScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        // ✅ LOGIC FIX: Show Main FAB ONLY on Home Screen (Index 0)
        // AND if _fabVisible is true (from scrolling)
        final bool showMainFab = _selectedIndex == 0 && _fabVisible;

        return Scaffold(
          extendBody: true,
          body: _pages[_selectedIndex],

          // Main FAB (Add Transaction)
          floatingActionButton: AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            // Slide down if hidden
            offset: showMainFab ? Offset.zero : const Offset(0, 2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showMainFab ? 1.0 : 0.0,
              child: FloatingActionButton(
                backgroundColor: _themeService.primaryBlue,
                shape: const CircleBorder(),
                elevation: 5,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  // Only active if visible to prevent phantom clicks
                  if (showMainFab) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Budget',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Analysis',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_rounded),
                label: 'Accounts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category_rounded),
                label: 'Categories',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            backgroundColor: _themeService.cardBg,
            selectedItemColor: _themeService.primaryBlue,
            unselectedItemColor: Colors.grey,
            elevation: 10,
            showUnselectedLabels: true,
          ),
        );
      },
    );
  }
}
