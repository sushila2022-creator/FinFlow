import 'package:flutter/material.dart';
import 'lib/models/transaction.dart';
import 'lib/widgets/transaction_tile.dart';

// This is a sample widget showing how the transaction list code should be properly structured
class TransactionListWidget extends StatelessWidget {
  final List<Transaction> filteredTransactions;

  const TransactionListWidget({
    super.key,
    required this.filteredTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 5. Transaction List
        if (filteredTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'No transactions found',
              style: TextStyle(fontSize: 16),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return TransactionTile(
                transaction: transaction,
              );
            },
          ),
      ],
    );
  }
}
