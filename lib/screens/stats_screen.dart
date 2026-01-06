import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/utils/utility.dart';
import 'package:finflow/utils/database_helper.dart';
import 'package:finflow/models/transaction.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedIndex = -1;
  bool _isIncome = false;
  List<Map<String, dynamic>> _categories = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadBudgetsAndCategories();
  }

  Future<void> _loadBudgetsAndCategories() async {
    final dbHelper = DatabaseHelper.instance;
    final categories = await dbHelper.getCategories();
    if (!mounted) return;

    setState(() {
      _categories = categories;
    });
  }

  Future<void> _showBudgetLimitDialog(BuildContext context, Map<String, dynamic> category) async {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final currencySymbol = currencyProvider.selectedCurrency['symbol'] ?? '₹';

    final TextEditingController controller = TextEditingController(
      text: (category['budget_limit'] as num?)?.toString() ?? '',
    );
    await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Budget for ${category['name']}'),
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
            onPressed: () async {
              // 1. Capture context-dependent tools BEFORE the async gap
              final navigator = Navigator.of(context);
              final scaffold = ScaffoldMessenger.of(context);
              final newLimit = double.tryParse(controller.text) ?? 0.0;

              // 2. Database Operation (Async)
              final dbHelper = DatabaseHelper.instance;
              await dbHelper.updateCategory({'id': category['id'], 'budget_limit': newLimit});

              // 3. Use CAPTURED tools (Safe to use without mounted check)
              navigator.pop(); // Close the dialog

              // 4. Refresh UI (Check mounted only for state update)
              if (mounted) {
                await _loadBudgetsAndCategories();
              }

              scaffold.showSnackBar(SnackBar(content: Text('Limit Updated to $currencySymbol${newLimit.toStringAsFixed(2)}')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  double _calculateSpentAmount(List<Transaction> transactions, int categoryId, DateTime startDate, DateTime endDate) {
    double spent = 0;
    for (var transaction in transactions) {
      if (transaction.categoryId == categoryId &&
          transaction.type == 'expense' &&
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))) {
        spent += transaction.amount.abs();
      }
    }
    return spent;
  }

  Map<String, double> _computeCategoryData(List<Transaction> transactions, bool isIncome) {
    final Map<String, double> categoryData = {};
    for (var transaction in transactions) {
      if ((isIncome && transaction.type == 'income') || (!isIncome && transaction.type == 'expense')) {
        final category = transaction.categoryName;
        final amount = transaction.amount;
        categoryData.update(category, (value) => value + amount, ifAbsent: () => amount);
      }
    }
    return categoryData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Expense',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _isIncome,
                  onChanged: (value) {
                    setState(() {
                      _isIncome = value;
                      _touchedIndex = -1; // Reset touched index when switching
                    });
                  },
                  activeThumbColor: const Color(0xFF00C853),
                  inactiveThumbColor: const Color(0xFFF44336),
                  inactiveTrackColor: const Color(0xFFF44336).withValues(alpha: 0.3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeTrackColor: const Color(0xFF00C853).withValues(alpha: 0.3),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Income',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<TransactionProvider, CurrencyProvider>(
          builder: (context, transactionProvider, currencyProvider, child) {
            // Filter transactions by selected month
            final monthTransactions = transactionProvider.transactions.where((transaction) {
              return transaction.date.year == _selectedMonth.year &&
                     transaction.date.month == _selectedMonth.month;
            }).toList();

            // Compute filtered data
            final filteredIncomeData = _computeCategoryData(monthTransactions, true);
            final filteredExpenseData = _computeCategoryData(monthTransactions, false);
            final selectedData = _isIncome ? filteredIncomeData : filteredExpenseData;
            final totalAmount = selectedData.values.fold(0.0, (sum, amount) => sum + amount);
            final currencySymbol = currencyProvider.selectedCurrency['symbol'] ?? '₹';

            // Prepare data for pie chart
            final List<PieChartSectionData> pieChartSections = _getPieChartSections(selectedData, _isIncome, context);

            return Column(
              children: [
                // Month Selector at the very top
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                            });
                          },
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A2540),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Total Amount Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: const Color(0xFF0A2540),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              _isIncome ? 'Total Income' : 'Total Expenses',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatIndianCurrency(totalAmount, symbol: currencySymbol),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                // Pie Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    height: 220,
                    child: selectedData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pie_chart_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No ${_isIncome ? 'income' : 'expense'} data available',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add some ${_isIncome ? 'income' : 'expenses'} to see analytics',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50,
                                  sections: pieChartSections,
                                ),
                              ),
                              Icon(
                                _isIncome ? Icons.account_balance_wallet : Icons.shopping_bag,
                                size: 40,
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Expanded list section
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Budget Status / Income Breakdown Section
                          Text(
                            _isIncome ? 'Income Breakdown' : 'Budget Status',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2540),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isIncome ? selectedData.isNotEmpty : _categories.where((cat) => cat['type'] == 'expense').isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _isIncome ? selectedData.length : _categories.where((cat) => cat['type'] == 'expense').length,
                                  itemBuilder: (context, index) {
                                    if (_isIncome) {
                                      final category = selectedData.keys.elementAt(index);
                                      final amount = selectedData.values.elementAt(index);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: _getCategoryColor(index, _isIncome),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Icon(
                                                    _getCategoryIcon(category),
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  category,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              formatIndianCurrency(amount, symbol: currencySymbol),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getCategoryColor(index, _isIncome),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      final category = _categories.where((cat) => cat['type'] == 'expense').elementAt(index);
                                      final categoryId = category['id'] as int;
                                      final categoryName = category['name'] as String;
                                      final limit = (category['budget_limit'] as num?)?.toDouble() ?? 0.0;
                                      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
                                      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
                                      final spent = _calculateSpentAmount(monthTransactions, categoryId, startDate, endDate);
                                      final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                                      final percentage = limit > 0 ? (spent / limit * 100).clamp(0.0, 100.0) : 0.0;

                                      return InkWell(
                                        onTap: () => _showBudgetLimitDialog(context, category),
                                        child: ListTile(
                                          title: Text(
                                            categoryName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              LinearProgressIndicator(
                                                value: limit > 0 ? progress : 0.0,
                                                backgroundColor: Colors.grey[300],
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  progress >= 1.0 ? Colors.red : (progress >= 0.8 ? Colors.orange : Colors.green),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Spent: ${formatIndianCurrency(spent, symbol: currencySymbol)}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  if (limit > 0)
                                                    Text(
                                                      'Limit: ${formatIndianCurrency(limit, symbol: currencySymbol)}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: Text(
                                            limit > 0 ? '${percentage.toStringAsFixed(1)}%' : 'No limit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: progress >= 1.0 ? Colors.red : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, double> data, bool isIncome, BuildContext context) {
    final List<PieChartSectionData> sections = [];
    final total = data.values.fold(0.0, (sum, amount) => sum + amount);

    data.forEach((category, amount) {
      final percentage = total > 0 ? (amount / total) * 100 : 0;
      final isTouched = data.keys.toList().indexOf(category) == _touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;

      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(data.keys.toList().indexOf(category), isIncome),
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return sections;
  }

  Color _getCategoryColor(int index, bool isIncome) {
    if (isIncome) {
      // Green shades for income
      final List<Color> incomeColors = [
        const Color(0xFF00C853), // Green
        const Color(0xFF4CAF50), // Light Green
        const Color(0xFF8BC34A), // Light Green 2
        const Color(0xFF388E3C), // Dark Green
        const Color(0xFF2E7D32), // Dark Green 2
        const Color(0xFF1B5E20), // Very Dark Green
        const Color(0xFF66BB6A), // Medium Green
        const Color(0xFF81C784), // Light Green 3
        const Color(0xFFA5D6A7), // Very Light Green
        const Color(0xFFC8E6C9), // Pale Green
      ];
      return incomeColors[index % incomeColors.length];
    } else {
      // Red/Blue shades for expense
      final List<Color> expenseColors = [
        const Color(0xFFF44336), // Red
        const Color(0xFF2196F3), // Blue
        const Color(0xFFE91E63), // Pink
        const Color(0xFF9C27B0), // Purple
        const Color(0xFF3F51B5), // Indigo
        const Color(0xFF00BCD4), // Cyan
        const Color(0xFFFF9800), // Orange
        const Color(0xFF795548), // Brown
        const Color(0xFFFFC107), // Amber
        const Color(0xFF607D8B), // Blue Grey
      ];
      return expenseColors[index % expenseColors.length];
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'travel':
        return Icons.directions_bus;
      case 'bills':
        return Icons.receipt;
      case 'shopping':
        return Icons.shopping_bag;
      case 'income':
        return Icons.attach_money;
      case 'housing':
        return Icons.home;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }
}
