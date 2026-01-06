import 'package:flutter/material.dart';

class CompleteEndingWidget extends StatelessWidget {
  final List<dynamic> filteredTransactions;

  const CompleteEndingWidget({
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
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'No transactions found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Transaction list would go here',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }
}
