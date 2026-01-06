import 'package:flutter/material.dart';
import 'package:finflow/utils/utility.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  final double income;
  final double expense;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF26A69A), // Teal
            Color(0xFF42A5F5), // Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            formatIndianCurrency(balance),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpense(
                context,
                title: 'Income',
                amount: income,
                icon: Icons.arrow_upward,
                color: Colors.greenAccent,
              ),
              _buildIncomeExpense(
                context,
                title: 'Expense',
                amount: expense,
                icon: Icons.arrow_downward,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpense(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            Text(
              formatIndianCurrency(amount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
