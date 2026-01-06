import 'package:finflow/features/auth/login_screen.dart';
import 'package:finflow/features/auth/signup_screen.dart';
import 'package:finflow/features/transactions/add_transaction_screen.dart';
import 'package:finflow/features/transactions/transaction_list_screen.dart';
import 'package:finflow/features/budgets/add_budget_screen.dart';
import 'package:finflow/features/budgets/budget_list_screen.dart';
import 'package:finflow/features/savings/add_savings_goal_screen.dart';
import 'package:finflow/features/savings/savings_goal_list_screen.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/features/transactions/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/screens/dashboard_screen.dart';
import 'package:finflow/screens/category_screen.dart';
import 'package:finflow/providers/theme_provider.dart';

import 'package:finflow/screens/main_screen.dart';

class FinFlowApp extends StatelessWidget {
  final ThemeProvider? themeProvider;

  const FinFlowApp({super.key, this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow',
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider?.themeMode ?? ThemeMode.system,
      initialRoute: '/main',
      routes: {
        '/main': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/addTransaction': (context) => const AddTransactionScreen(),
        '/transactions': (context) => const TransactionListScreen(),
        '/addBudget': (context) => const AddBudgetScreen(),
        '/budgets': (context) => const BudgetListScreen(),
        '/addSavingsGoal': (context) => const AddSavingsGoalScreen(),
        '/savingsGoals': (context) => const SavingsGoalListScreen(),
        '/transactionDetail': (context) => TransactionDetailScreen(
              transaction: ModalRoute.of(context)!.settings.arguments as Transaction,
            ),
        '/dashboard': (context) => const DashboardScreen(),
        '/home': (context) => const MainScreen(),
        '/categories': (context) => const CategoryScreen(),
      },
    );
  }
}
