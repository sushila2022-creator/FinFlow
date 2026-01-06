import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/screens/stats_screen.dart';
import 'package:finflow/services/notification_service.dart';
import 'package:finflow/services/recurring_transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:finflow/screens/settings_screen.dart';
import 'package:finflow/screens/dashboard_screen.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:provider/provider.dart';
import 'package:finflow/services/auth/firebase_auth_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuthService _authService = FirebaseAuthService();

  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    const StatsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final notificationService = NotificationService();
      final recurringTransactionService =
          RecurringTransactionService(transactionProvider, notificationService);
      recurringTransactionService.createRecurringTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.jpg',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'FinFlow',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF00C853),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0A2540),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Transact',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
