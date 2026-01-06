import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finflow/utils/database_helper.dart'; // Corrected import path
import 'package:finflow/models/budget.dart'; // Corrected import path
import 'package:finflow/models/transaction.dart'; // Corrected import path
import 'package:finflow/utils/utility.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  late Future<List<Budget>> _budgetsFuture;
  late Future<List<Transaction>> _transactionsFuture; // To fetch transactions for spending calculation

  @override
  void initState() {
    super.initState();
    _budgetsFuture = _loadBudgets();
    _transactionsFuture = _loadTransactions(); // Load transactions to calculate spending
  }

  Future<List<Budget>> _loadBudgets() async {
    final dbHelper = DatabaseHelper.instance;
    final List<Map<String, dynamic>> budgetMaps = await dbHelper.getBudgets();
    return budgetMaps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<List<Transaction>> _loadTransactions() async {
    final dbHelper = DatabaseHelper.instance;
    final List<Map<String, dynamic>> transactionMaps = await dbHelper.getTransactions();
    return transactionMaps.map((map) => Transaction.fromMap(map)).toList();
  }

  // Function to calculate total spending for a specific category within a budget period
  double _calculateSpentAmount(List<Transaction> allTransactions, String category, DateTime startDate, DateTime endDate) {
    double spent = 0;
    for (var transaction in allTransactions) {
      // Check if the transaction is within the budget period and matches the category
      if (transaction.categoryName == category &&
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) && // Include start date
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))) { // Include end date
        if (transaction.type == 'expense') { // Only consider expenses
          spent += transaction.amount.abs();
        }
      }
    }
    return spent;
  }

  // Function to refresh the list after an operation (e.g., delete)
  void _refreshBudgets() {
    setState(() {
      _budgetsFuture = _loadBudgets();
      _transactionsFuture = _loadTransactions(); // Reload transactions as well
    });
  }

  Future<void> _deleteBudget(int id) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.deleteBudget(id);
    _refreshBudgets(); // Refresh the list after deletion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted')),
      );
    }
  }

  Future<void> _editBudgetAmount(Budget budget) async {
    final TextEditingController controller = TextEditingController(
      text: budget.amount.toString(),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Budget Limit for ${budget.category}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Budget Limit'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? budget.amount;
              Navigator.of(context).pop(newLimit);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result != budget.amount) {
      final updatedBudget = Budget(
        id: budget.id,
        category: budget.category,
        amount: result,
        startDate: budget.startDate,
        endDate: budget.endDate,
      );
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateBudget(updatedBudget.toMap());
      _refreshBudgets(); // Refresh the UI immediately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget limit updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/addBudget').then((_) => _refreshBudgets());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Budget>>(
        future: _budgetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No budgets set yet. Add one!'));
          } else {
            final budgets = snapshot.data!;
            return FutureBuilder<List<Transaction>>(
              future: _transactionsFuture,
              builder: (context, transactionSnapshot) {
                if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (transactionSnapshot.hasError) {
                  return Center(child: Text('Error loading transactions: ${transactionSnapshot.error}'));
                } else {
                  final transactions = transactionSnapshot.data ?? [];
                  return ListView.builder(
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      final spentAmount = _calculateSpentAmount(transactions, budget.category, budget.startDate, budget.endDate);
                      final remainingAmount = budget.amount - spentAmount;
                      final progress = (spentAmount / budget.amount).clamp(0.0, 1.0); // Clamp to 0-1 range

                      final formattedStartDate = DateFormat('yyyy-MM-dd').format(budget.startDate);
                      final formattedEndDate = DateFormat('yyyy-MM-dd').format(budget.endDate);

                      return Dismissible(
                        key: Key(budget.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _deleteBudget(budget.id!);
                        },
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: const Text('Are you sure you want to delete this budget?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: InkWell(
                            onTap: () => _editBudgetAmount(budget),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    budget.category,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Period: $formattedStartDate to $formattedEndDate',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress > 0.8 ? Colors.red : Colors.green, // Color based on progress
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Spent: ${formatIndianCurrency(spentAmount)}',
                                        style: TextStyle(color: spentAmount > budget.amount ? Colors.red : Colors.black54),
                                      ),
                                      Text(
                                        'Remaining: ${formatIndianCurrency(remainingAmount)}',
                                        style: TextStyle(color: remainingAmount < 0 ? Colors.red : Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
