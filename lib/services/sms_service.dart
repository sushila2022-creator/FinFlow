import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finflow/utils/debug_logger.dart';

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

  void stopScanning() {
    stop();
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
      logError('Error checking SMS', error: e);
    }
  }

  void _processSms(SmsMessage message) {
    // Check if user is authenticated before processing SMS
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logError('Cannot process SMS: user not authenticated');
      return;
    }

    final body = message.body?.toLowerCase() ?? '';
    final address = message.address?.toLowerCase() ?? '';

    // Check if it's a bank SMS with better bank detection
    final bankKeywords = [
      'sbi',
      'state bank of india',
      'statebank',
      'hdfc',
      'hdfc bank',
      'icici',
      'icici bank',
      'axis',
      'axis bank',
      'pnb',
      'punjab national bank',
      'kotak',
      'kotak mahindra bank',
      'bob',
      'bank of baroda',
      'canara',
      'canara bank',
      'boi',
      'bank of india',
      'sbi card',
      'hdfc card',
      'icici card',
      'axis card',
    ];

    bool isBankSms = bankKeywords.any(
      (keyword) => address.contains(keyword) || body.contains(keyword),
    );

    if (!isBankSms) return;

    // Parse amount with better regex
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

    // Determine if debit or credit with better logic
    bool isDebit = _determineTransactionType(body);
    bool isCredit = !isDebit;

    // Extract bank name
    String bankName = _extractBankName(body, address);

    logError(
      'SMS Processing: Amount: $amount, Merchant: $merchant, Bank: $bankName, IsDebit: $isDebit, IsCredit: $isCredit, Body: $body',
    );

    // Show detected transaction card on dashboard
    _showDetectedTransactionCard(
      amount: amount,
      merchant: merchant,
      category: category,
      date: date,
      body: body,
      isDebit: isDebit,
      isCredit: isCredit,
      bankName: bankName,
    );
  }

  bool _determineTransactionType(String body) {
    // Better logic to determine transaction type
    final lowerBody = body.toLowerCase();

    // Keywords that indicate debit (money going out)
    final debitKeywords = [
      'debited',
      'debit',
      'spent',
      'purchase',
      'withdrawn',
      'withdrawal',
      'charged',
      'deducted',
      'payment',
      'paid',
      'transfer',
      'sent',
      'outgoing',
    ];

    // Keywords that indicate credit (money coming in)
    final creditKeywords = [
      'credited',
      'credit',
      'received',
      'deposit',
      'refund',
      'transfer',
      'incoming',
      'salary',
      'interest',
      'bonus',
    ];

    // Count debit and credit indicators
    int debitCount = debitKeywords.fold(
      0,
      (count, keyword) => lowerBody.contains(keyword) ? count + 1 : count,
    );

    int creditCount = creditKeywords.fold(
      0,
      (count, keyword) => lowerBody.contains(keyword) ? count + 1 : count,
    );

    // If both debit and credit keywords found, prioritize based on context
    if (debitCount > 0 && creditCount > 0) {
      // Check for specific patterns
      if (lowerBody.contains('transfer') && lowerBody.contains('to')) {
        // Money transferred TO someone = debit
        return true;
      } else if (lowerBody.contains('transfer') && lowerBody.contains('from')) {
        // Money transferred FROM someone = credit
        return false;
      }
      // Default to debit if both found
      return true;
    }

    // Return true if more debit indicators, false if more credit indicators
    return debitCount > creditCount;
  }

  String _extractBankName(String body, String address) {
    // Better bank name extraction
    final lowerBody = body.toLowerCase();
    final lowerAddress = address.toLowerCase();

    // Comprehensive bank name mappings
    final bankMappings = {
      // SBI variations
      'sbi': 'State Bank of India',
      'state bank of india': 'State Bank of India',
      'statebank': 'State Bank of India',

      // HDFC variations
      'hdfc': 'HDFC Bank',
      'hdfc bank': 'HDFC Bank',

      // ICICI variations
      'icici': 'ICICI Bank',
      'icici bank': 'ICICI Bank',

      // Axis variations
      'axis': 'Axis Bank',
      'axis bank': 'Axis Bank',

      // PNB variations
      'pnb': 'Punjab National Bank',
      'punjab national bank': 'Punjab National Bank',

      // Kotak variations
      'kotak': 'Kotak Mahindra Bank',
      'kotak mahindra bank': 'Kotak Mahindra Bank',

      // BOB variations
      'bob': 'Bank of Baroda',
      'bank of baroda': 'Bank of Baroda',

      // Canara variations
      'canara': 'Canara Bank',
      'canara bank': 'Canara Bank',

      // BOI variations
      'boi': 'Bank of India',
      'bank of india': 'Bank of India',

      // Card variations
      'sbi card': 'SBI Card',
      'hdfc card': 'HDFC Card',
      'icici card': 'ICICI Card',
      'axis card': 'Axis Card',
    };

    // Check address first (usually contains bank name)
    for (final entry in bankMappings.entries) {
      if (lowerAddress.contains(entry.key)) {
        return entry.value;
      }
    }

    // Check body if not found in address
    for (final entry in bankMappings.entries) {
      if (lowerBody.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try to extract from address pattern like "HDFCBANK" or "SBIN"
    final bankCodePatterns = [
      RegExp(r'(?:sbi|hdfc|icici|axis|pnb|kotak|bob|canara|boi)(?:\s|$|@)'),
    ];

    for (final pattern in bankCodePatterns) {
      final match = pattern.firstMatch(lowerAddress);
      if (match != null && match.group(0) != null) {
        final code = match.group(0)!.trim();
        return bankMappings[code] ?? code.toUpperCase();
      }
    }

    return 'Unknown Bank';
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

  void _showDetectedTransactionCard({
    required double amount,
    required String merchant,
    required String category,
    required DateTime date,
    required String body,
    required bool isDebit,
    required bool isCredit,
    required String bankName,
  }) {
    // Verify user is still authenticated before triggering callback
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logError('Cannot show transaction card: user not authenticated');
      return;
    }

    onTransactionDetected?.call({
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'date': date,
      'body': body,
      'isDebit': isDebit,
      'isCredit': isCredit,
      'bankName': bankName,
      'userId': user.uid, // Include userId for proper Firestore mapping
    });
  }
}
