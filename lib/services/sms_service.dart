import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();

  factory SmsService() => _instance;

  SmsService._internal();

  final SmsQuery smsQuery = SmsQuery();
  bool isScanning = false;
  Function(Map<String, dynamic>)? onTransactionDetected;

  void start() {
    isScanning = true;
    requestSmsPermission();
  }

  void startScanning() {
    start();
  }

  void stop() {
    isScanning = false;
  }

  Future<bool> requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        return false;
      }
    }
    await checkRecentSms();
    return true;
  }

  Future<void> checkRecentSms() async {
    try {
      // Get recent SMS messages
      final messages = await smsQuery.querySms(kinds: [SmsQueryKind.inbox]);

      for (final message in messages) {
        _processSms(message);
      }
    } catch (e) {
      debugPrint('Error checking SMS: $e');
    }
  }

  void _processSms(SmsMessage message) {
    final body = message.body?.toLowerCase() ?? '';
    final address = message.address?.toLowerCase() ?? '';

    // Check if it's a bank SMS (you can expand this list)
    final bankKeywords = [
      'sbi',
      'hdfc',
      'icici',
      'axis',
      'pnb',
      'bank',
      'card',
      'debit',
      'credit',
    ];

    bool isBankSms = bankKeywords.any(
      (keyword) => address.contains(keyword) || body.contains(keyword),
    );

    if (!isBankSms) return;

    // Parse amount
    final amountRegex = RegExp(r'(?:rs\.?|inr|₹)\s*(\d+(?:,\d+)*(?:\.\d{2})?)');
    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch == null) return;

    final amountString = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    final amount = double.tryParse(amountString);
    if (amount == null || amount <= 0) return;

    // Parse merchant/date (simplified)
    String merchant = _extractMerchant(body);
    String category = _categorizeTransaction(body, merchant);
    DateTime date = message.date ?? DateTime.now();

    // Determine if debit or credit
    bool isDebit =
        body.contains('debit') ||
        body.contains('spent') ||
        body.contains('purchase') ||
        body.contains('withdrawn');

    if (isDebit) {
      // Show detected transaction card on dashboard
      _showDetectedTransactionCard(amount, merchant, category, date, body);
    }
  }

  String _extractMerchant(String body) {
    // Simple merchant extraction - look for common patterns
    final merchantPatterns = [
      RegExp(r'at\s+([A-Za-z\s]+?)(?:\s|$|,)'),
      RegExp(r'from\s+([A-Za-z\s]+?)(?:\s|$|,)'),
      RegExp(r'to\s+([A-Za-z\s]+?)(?:\s|$|,)'),
    ];

    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    return 'Unknown Merchant';
  }

  String _categorizeTransaction(String body, String merchant) {
    // Categorize based on keywords in body or merchant
    final lowerBody = body.toLowerCase();
    final lowerMerchant = merchant.toLowerCase();

    if (lowerBody.contains('amazon') || lowerMerchant.contains('amazon')) {
      return 'Shopping';
    } else if (lowerBody.contains('zomato') ||
        lowerBody.contains('swiggy') ||
        lowerBody.contains('food') ||
        lowerMerchant.contains('zomato') ||
        lowerMerchant.contains('swiggy')) {
      return 'Food';
    } else if (lowerBody.contains('uber') ||
        lowerBody.contains('ola') ||
        lowerBody.contains('taxi') ||
        lowerMerchant.contains('uber') ||
        lowerMerchant.contains('ola')) {
      return 'Transport';
    } else if (lowerBody.contains('netflix') ||
        lowerBody.contains('prime') ||
        lowerBody.contains('subscription') ||
        lowerMerchant.contains('netflix') ||
        lowerMerchant.contains('prime')) {
      return 'Entertainment';
    } else if (lowerBody.contains('atm') || lowerBody.contains('withdraw')) {
      return 'Cash Withdrawal';
    } else if (lowerBody.contains('bill') || lowerBody.contains('utility')) {
      return 'Bills';
    } else if (lowerBody.contains('fuel') ||
        lowerBody.contains('petrol') ||
        lowerBody.contains('diesel')) {
      return 'Fuel';
    } else {
      return 'Other';
    }
  }

  void _showDetectedTransactionCard(
    double amount,
    String merchant,
    String category,
    DateTime date,
    String body,
  ) {
    onTransactionDetected?.call({
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'date': date,
      'body': body,
    });
  }
}
