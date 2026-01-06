import 'package:finflow/models/transaction.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/services/notification_service.dart';

class RecurringTransactionService {
  final TransactionProvider _transactionProvider;
  final NotificationService _notificationService;

  RecurringTransactionService(this._transactionProvider, this._notificationService);

  Future<void> createRecurringTransactions() async {
    final recurringTransactions = await _transactionProvider.getRecurringTransactions();

    for (final transaction in recurringTransactions) {
      if (_isDue(transaction)) {
        final newTransaction = Transaction(
          description: transaction.description,
          amount: transaction.amount,
          currencyCode: transaction.currencyCode,
          date: DateTime.now(),
          categoryId: transaction.categoryId,
          categoryName: transaction.categoryName,
          type: transaction.type,
          accountId: transaction.accountId,
          notes: transaction.notes,
        );
        await _transactionProvider.addTransaction(newTransaction);
        await _notificationService.showNotification(
          'Recurring Transaction',
          'A new transaction for ${transaction.description} has been added.',
        );
      }
    }
  }

  bool _isDue(Transaction transaction) {
    if (transaction.recurrenceEndDate != null &&
        transaction.recurrenceEndDate!.isBefore(DateTime.now())) {
      return false;
    }

    final now = DateTime.now();
    final lastTransactionDate = transaction.date;

    switch (transaction.recurrenceFrequency) {
      case 'Daily':
        return now.difference(lastTransactionDate).inDays >= 1;
      case 'Weekly':
        return now.difference(lastTransactionDate).inDays >= 7;
      case 'Monthly':
        return now.month != lastTransactionDate.month || now.year != lastTransactionDate.year;
      default:
        return false;
    }
  }
}
