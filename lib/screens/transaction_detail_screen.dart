import 'package:finflow/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finflow/utils/utility.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Define Poppins font family

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction Detail',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.categoryName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondaryLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.category, color: AppTheme.primaryColor, size: 30),
                const SizedBox(width: 12),
                Text(
                  formatIndianCurrency(transaction.amount.abs()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == 'expense'
                        ? AppTheme.expenseColor
                        : AppTheme.incomeColor,
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
