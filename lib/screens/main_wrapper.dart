import 'package:flutter/material.dart';
import 'package:finflow/screens/dashboard_screen.dart';
import 'package:finflow/screens/analytics_screen.dart';
import 'package:finflow/screens/settings_screen.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:finflow/screens/transactions_screen.dart';
import 'package:finflow/providers/navigation_provider.dart';
import 'package:provider/provider.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  void _onTabTapped(int index) {
    Provider.of<NavigationProvider>(context, listen: false).setTab(index);
  }

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: const AddTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final List<Widget> screens = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const AnalyticsScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: navProvider.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navProvider.currentIndex != 0) {
          navProvider.switchToDashboard();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: navProvider.currentIndex,
          children: screens,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddTransaction,
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navProvider.currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0D2B45),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
