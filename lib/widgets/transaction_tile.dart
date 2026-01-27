import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: transaction.isIncome
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: transaction.isIncome ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            transaction.category,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: currencyProvider.currentCurrencySymbol,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: transaction.isIncome ? Colors.green : Colors.red,
                  ),
                ),
                TextSpan(
                  text: transaction.amount.abs().toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: transaction.isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
