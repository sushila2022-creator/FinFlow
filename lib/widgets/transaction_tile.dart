import 'package:finflow/models/transaction.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finflow/utils/utility.dart';
import 'package:provider/provider.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type.toLowerCase() == 'income';
    final amountColor = isIncome ? Colors.green : Colors.red;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Compact spacing - reduced margins
    final cardMargin = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 6.0 : 12.0,
      vertical: isSmallScreen ? 3.0 : 6.0,
    );

    return Container(
      margin: cardMargin,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(transactionToEdit: transaction.toMap()),
              settings: RouteSettings(
                arguments: transaction,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          child: Row(
            children: [
              // Icon: CircleAvatar (radius 20) with the category icon
              CircleAvatar(
                backgroundColor: getCategoryBackgroundColor(transaction.categoryName),
                radius: 20,
                child: Icon(
                  getCategoryIconByName(transaction.categoryName),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              
              // Gap: SizedBox(width: 12)
              const SizedBox(width: 12),
              
              // Name: Category Name Text in Expanded with proper styling
              Expanded(
                child: Text(
                  transaction.categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              
              // Right Side Group: Row with mainAxisSize: MainAxisSize.min
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date: Text widget
                  Text(
                    DateFormat('MMM d').format(transaction.date), // e.g., 'Dec 16'
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  
                  // Gap: SizedBox(width: 8)
                  const SizedBox(width: 8),
                  
                  // Amount: Bold, Green for Income, Red for Expense
                  Consumer<CurrencyProvider>(
                    builder: (context, currencyProvider, child) {
                      final currencySymbol = currencyProvider.selectedCurrency['symbol'] ?? '₹';
                      final formattedAmount = formatIndianCurrency(transaction.amount.abs(), symbol: currencySymbol);
                      
                      // Add prefix based on transaction type
                      final amountPrefix = isIncome ? '+' : '-';
                      final displayAmount = '$amountPrefix$formattedAmount';

                      return Text(
                        displayAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  
                  // Menu: The existing three-dot PopupMenuButton
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(transactionToEdit: transaction.toMap()),
                            settings: RouteSettings(
                              arguments: transaction,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmationDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 18),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 18, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTransaction(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.deleteTransaction(transaction.id!);
  }
}
