import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finflow/providers/transaction_provider.dart'; // Corrected import path
import 'package:finflow/widgets/transaction_tile.dart'; // Corrected import path
import 'package:finflow/models/transaction.dart'; // Corrected import path

// Helper class to select multiple values from the provider
class _TransactionScreenData {
  final List<Transaction> transactions;
  final String currencySymbol;

  _TransactionScreenData({
    required this.transactions,
    required this.currencySymbol,
  });

  // Override equality to ensure widget rebuilds only when necessary
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TransactionScreenData &&
          runtimeType == other.runtimeType &&
          transactions == other.transactions &&
          currencySymbol == other.currencySymbol;

  @override
  int get hashCode => transactions.hashCode ^ currencySymbol.hashCode;
}

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  Widget build(BuildContext context) {
    // Use context.select to rebuild only when transactions or currencySymbol changes
    final data = context.select<TransactionProvider, _TransactionScreenData>(
      (provider) => _TransactionScreenData(
        transactions: provider.transactions, // Directly access the property
        currencySymbol: provider.currencySymbol, // Directly access the property
      ),
    );

    final allTransactions = data.transactions;
    final incomeTransactions = allTransactions.where((t) => t.type.toLowerCase() == 'income').toList();
    final expenseTransactions = allTransactions.where((t) => t.type.toLowerCase() == 'expense').toList();

    return DefaultTabController(
      length: 2, // Two tabs: Income and Expenses
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          backgroundColor: Theme.of(context).primaryColor,
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.secondary, // Green accent color
            labelColor: Theme.of(context).colorScheme.secondary, // Selected tab text color (green)
            unselectedLabelColor: Colors.white, // Unselected tab text color (white)
            tabs: const [
              Tab(text: 'Income'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Income Tab
            incomeTransactions.isEmpty
                ? const Center(child: Text('No income yet.'))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListView.builder(
                      itemCount: incomeTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = incomeTransactions[index];
                        return TransactionTile(transaction: transaction);
                      },
                    ),
                  ),
            // Expenses Tab
            expenseTransactions.isEmpty
                ? const Center(child: Text('No expenses yet.'))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListView.builder(
                      itemCount: expenseTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = expenseTransactions[index];
                        return TransactionTile(transaction: transaction);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
