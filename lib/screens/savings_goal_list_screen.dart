import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finflow/utils/database_helper.dart'; // Corrected import path
import 'package:finflow/models/savings_goal.dart'; // Corrected import path
import 'package:finflow/utils/utility.dart';

class SavingsGoalListScreen extends StatefulWidget {
  const SavingsGoalListScreen({super.key});

  @override
  State<SavingsGoalListScreen> createState() => _SavingsGoalListScreenState();
}

class _SavingsGoalListScreenState extends State<SavingsGoalListScreen> {
  late Future<List<SavingsGoal>> _savingsGoalsFuture;

  @override
  void initState() {
    super.initState();
    _savingsGoalsFuture = _loadSavingsGoals();
  }

  Future<List<SavingsGoal>> _loadSavingsGoals() async {
    final dbHelper = DatabaseHelper.instance;
    final List<Map<String, dynamic>> savingsGoalMaps = await dbHelper.getSavingsGoals();
    return savingsGoalMaps.map((map) => SavingsGoal.fromMap(map)).toList();
  }

  // Function to refresh the list after an operation (e.g., delete)
  void _refreshSavingsGoals() {
    setState(() {
      _savingsGoalsFuture = _loadSavingsGoals();
    });
  }

  Future<void> _deleteSavingsGoal(int id) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.deleteSavingsGoal(id);
    _refreshSavingsGoals(); // Refresh the list after deletion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/addSavingsGoal').then((_) => _refreshSavingsGoals());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SavingsGoal>>(
        future: _savingsGoalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No savings goals yet. Add one!'));
          } else {
            final savingsGoals = snapshot.data!;
            return ListView.builder(
              itemCount: savingsGoals.length,
              itemBuilder: (context, index) {
                final goal = savingsGoals[index];
                final remainingAmount = goal.targetAmount - goal.currentAmount;
                final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0); // Clamp to 0-1 range

                final formattedTargetDate = DateFormat('yyyy-MM-dd').format(goal.targetDate);

                return Dismissible(
                  key: Key(goal.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteSavingsGoal(goal.id!);
                  },
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text('Are you sure you want to delete this savings goal?'),
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
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Target Date: $formattedTargetDate',
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
                                'Saved: ${formatIndianCurrency(goal.currentAmount)}',
                                style: TextStyle(color: goal.currentAmount > goal.targetAmount ? Colors.red : Colors.black54),
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
                );
              },
            );
          }
        },
      ),
    );
  }
}
