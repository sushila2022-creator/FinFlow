import 'package:finflow/models/transaction.dart'; // Corrected import path
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finflow/utils/utility.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Define Poppins font family
    const String poppinsFont = 'Poppins';
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.categoryName,
              style: const TextStyle(
              fontFamily: poppinsFont,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
              style: TextStyle(fontFamily: poppinsFont, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                Icons.category,
                color: primaryColor,
                size: 30,
              ),
              const SizedBox(width: 12),
                Text(
                  formatIndianCurrency(transaction.amount),
                  style: TextStyle(
                    fontFamily: poppinsFont,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == 'expense' ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            // Add more details here if available in the Transaction model
          ],
        ),
      ),
    );
  }
}
