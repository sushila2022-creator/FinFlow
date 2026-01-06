import 'package:flutter/material.dart';
import 'package:finflow/screens/dashboard_screen.dart';
import 'package:finflow/screens/transaction_list_screen.dart';
import 'package:finflow/screens/stats_screen.dart';
import 'package:finflow/screens/settings_screen.dart';
import 'package:finflow/widgets/bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionListScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
      floatingActionButton: _selectedIndex != 0 ? FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/addTransaction'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
