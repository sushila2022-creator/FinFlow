import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finflow/models/user_model.dart';
import 'package:finflow/utils/debug_logger.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();

  factory SmsService() => _instance;

  SmsService._internal();

  final SmsQuery smsQuery = SmsQuery();
  bool isScanning = false;
  Function(Map<String, dynamic>)? onTransactionDetected;
  Function()? onSmsLimitReached;

  static const int freeSmsTransactionLimit = 15;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> start() async {
    return await startScanningWithPermission();
  }

  Future<bool> startScanning() async {
    return await startScanningWithPermission();
  }

  void stopScanning() {
    stop();
  }

  void stop() {
    isScanning = false;
  }

  Future<PermissionStatus> getSmsPermissionStatus() async {
    try {
      return await Permission.sms.status;
    } catch (e) {
      logError(
        'Error checking SMS permission status',
        error: e,
        tag: 'SmsService',
      );
      return PermissionStatus.denied;
    }
  }

  Future<bool> hasSmsPermission() async {
    final status = await getSmsPermissionStatus();
    return status.isGranted;
  }

  Future<bool> isPermissionPermanentlyDenied() async {
    final status = await getSmsPermissionStatus();
    return status.isPermanentlyDenied;
  }

  Future<void> openAppSettings() async {
    try {
      // Use top-level function from permission_handler package
      await Permission.sms.request();
    } catch (e) {
      logError('Error opening app settings', error: e, tag: 'SmsService');
    }
  }

  Future<bool> requestSmsPermission() async {
    logDebug('Requesting SMS permission...', tag: 'SmsService');
    try {
      final status = await getSmsPermissionStatus();
      logDebug('Initial SMS permission status: $status', tag: 'SmsService');

      if (status.isGranted) {
        logDebug('✅ SMS permission already granted', tag: 'SmsService');
        return true;
      }

      if (status.isPermanentlyDenied) {
        logWarning(
          '🔒 SMS permission permanently denied. User must enable it in app settings.',
          tag: 'SmsService',
        );
        isScanning = false;
        return false;
      }

      if (status.isDenied) {
        logDebug(
          '📋 Permission is denied, showing request dialog',
          tag: 'SmsService',
        );
      }

      final result = await Permission.sms.request();
      logDebug('📩 SMS permission request result: $result', tag: 'SmsService');

      if (result.isGranted) {
        logDebug('✅ SMS permission granted successfully', tag: 'SmsService');
        return true;
      } else if (result.isPermanentlyDenied) {
        logWarning(
          '🔒 User selected "Don\'t ask again" - permission permanently denied',
          tag: 'SmsService',
        );
        isScanning = false;
        return false;
      } else {
        logWarning('❌ SMS permission denied by user', tag: 'SmsService');
        isScanning = false;
        return false;
      }
    } catch (e) {
      logError(
        '❌ Error requesting SMS permission',
        error: e,
        tag: 'SmsService',
      );
      isScanning = false;
      return false;
    }
  }

  Future<bool> startScanningWithPermission() async {
    // First verify permission before proceeding
    final hasPermission = await hasSmsPermission();

    if (!hasPermission) {
      logDebug('No SMS permission, requesting first...', tag: 'SmsService');
      final granted = await requestSmsPermission();
      if (!granted) {
        logDebug(
          'Cannot start scanning: permission not granted',
          tag: 'SmsService',
        );
        isScanning = false;
        return false;
      }
    }

    // Double check permission before accessing SMS
    final finalCheck = await hasSmsPermission();
    if (!finalCheck) {
      logError(
        'Permission check failed at final validation',
        tag: 'SmsService',
      );
      isScanning = false;
      return false;
    }

    logDebug(
      '✅ All permission checks passed, starting SMS scanning',
      tag: 'SmsService',
    );
    isScanning = true;
    await checkRecentSms();
    return true;
  }

  Future<void> checkRecentSms() async {
    if (!isScanning) {
      logDebug(
        'SmsService not in scanning mode, skipping check.',
        tag: 'SmsService',
      );
      return;
    }

    // Critical safety check: Verify permission BEFORE accessing SMS API
    final hasPermission = await hasSmsPermission();
    if (!hasPermission) {
      logWarning(
        '⚠️ Attempted to check SMS without permission! Stopping scanner.',
        tag: 'SmsService',
      );
      isScanning = false;
      return;
    }

    logDebug('Fetching recent SMS messages...', tag: 'SmsService');

    try {
      // Get recent SMS messages - limit to 100 for better coverage during testing
      final messages = await smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 100,
      );

      logDebug(
        'Retrieved ${messages.length} SMS messages from inbox',
        tag: 'SmsService',
      );

      if (messages.isEmpty) {
        logDebug('No SMS messages found in inbox', tag: 'SmsService');
        return;
      }

      int processedCount = 0;
      for (final message in messages) {
        if (!isScanning) {
          logDebug(
            'Scanning stopped during processing cycle',
            tag: 'SmsService',
          );
          break;
        }
        _processSms(message);
        processedCount++;
      }
      logDebug(
        'Finished processing cycle: $processedCount messages inspected',
        tag: 'SmsService',
      );
    } catch (e) {
      logError('Error checking SMS', error: e, tag: 'SmsService');
    }
  }

  void _processSms(SmsMessage message) async {
    // Check if user is authenticated before processing SMS
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logError('Cannot process SMS: user not authenticated');
      return;
    }

    // Check user premium status and transaction limit
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      logError('Cannot process SMS: user document not found');
      return;
    }

    final userModel = UserModel.fromSnapshot(userDoc);

    // Allow unlimited processing if premium is active
    if (!userModel.isPremiumActive) {
      // Check limit BEFORE processing
      if (userModel.smsTransactionCount >= freeSmsTransactionLimit) {
        logDebug(
          'SMS transaction limit reached for free user. Stopping processing. Current: ${userModel.smsTransactionCount} / $freeSmsTransactionLimit',
          tag: 'SmsService',
        );
        onSmsLimitReached?.call();
        isScanning = false;
        return;
      }

      // Increment count FIRST before processing to prevent race conditions
      final newCount = userModel.smsTransactionCount + 1;
      await _firestore.collection('users').doc(user.uid).update({
        'smsTransactionCount': newCount,
      });

      logDebug(
        'SMS transaction count incremented: $newCount / $freeSmsTransactionLimit',
        tag: 'SmsService',
      );

      // Double check after increment to be 100% safe
      if (newCount > freeSmsTransactionLimit) {
        logDebug(
          'Limit exceeded after increment, aborting processing',
          tag: 'SmsService',
        );
        return;
      }
    }

    logDebug('----------------------------------------', tag: 'SmsService');
    logDebug('Processing SMS from: ${message.address}', tag: 'SmsService');
    logDebug('Raw Body: ${message.body}', tag: 'SmsService');

    final body = message.body?.toLowerCase() ?? '';
    final address = (message.address ?? '').toLowerCase();

    if (body.isEmpty) {
      logDebug('Ignoring empty SMS body', tag: 'SmsService');
      return;
    }

    // Step 1: Explicit Exclusions (Security & Noise)
    final exclusions = [
      'otp',
      'verification code',
      'verify',
      'password',
      'passcode',
      'secret code',
      'offer',
      'coupon',
      'discount',
      'cashback', // Cashback can be valid but often promotional
      'win',
      'limited time',
      'free',
      'congratulations',
      'lottery',
    ];

    if (exclusions.any((ex) => body.contains(ex))) {
      logDebug(
        'Exclusion keyword detected. Skipping for security/noise reduction.',
        tag: 'SmsService',
      );
      return;
    }

    // Step 2: Detect presence of an amount (Strict requirement)
    // Improved regex to handle various decimal places, currency variations (prefix/suffix), and /- suffixes
    final amountRegex = RegExp(
      r'(?:(?:rs\.?|inr|₹|usd|\$)\s*(\d+(?:,\d+)*(?:\.\d+)?)\b)|(?:\b(\d+(?:,\d+)*(?:\.\d+)?)\s*(?:rs\.?|inr|₹|usd|\$|/-))',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(body);

    if (amountMatch == null) {
      logDebug(
        'SMS Filtered: No amount pattern found in body.',
        tag: 'SmsService',
      );
      return;
    }

    // Extraction logic for the new regex
    final amountString = (amountMatch.group(1) ?? amountMatch.group(2) ?? '')
        .replaceAll(',', '');
    final amount = double.tryParse(amountString);
    if (amount == null || amount <= 0) {
      logDebug(
        'SMS Filtered: Invalid parsed amount ($amountString)',
        tag: 'SmsService',
      );
      return;
    }

    // Step 3: Strict Financial Context (Required keywords)
    final coreKeywords = [
      'debited',
      'credited',
      'spent',
      'withdrawn',
      'paid',
      'received',
      'txn',
      'transaction',
      'a/c',
      'account',
      'upi',
      'sent',
      'transferred',
      'transfer',
      'added',
      'loaded',
      'purchase',
      'vpa',
      'payment',
      'ref-no',
      'ref no',
      'avbl bal',
      'available balance',
    ];

    bool hasCoreKeyword = coreKeywords.any((kw) => body.contains(kw));

    if (!hasCoreKeyword) {
      logDebug(
        'SMS Filtered: No core financial keywords (debited/credited/etc) found in body.',
        tag: 'SmsService',
      );
      return;
    }

    logDebug('Transaction verified! Parsing details...', tag: 'SmsService');

    // Parse merchant/date (simplified)
    String merchant = _extractMerchant(body);
    String category = _categorizeTransaction(body, merchant);
    DateTime date = message.date ?? DateTime.now();

    // Determine if debit or credit with better logic
    bool isDebit = _determineTransactionType(body);
    bool isCredit = !isDebit;

    // Extract bank name
    String bankName = _extractBankName(body, address);

    logDebug(
      'Transaction Successfully Parsed: $bankName | $amount | ${isDebit ? "Debit" : "Credit"}',
      tag: 'SmsService',
    );

    // Show detected transaction card on
    if (!userModel.isPremiumActive) {
      final newCount = userModel.smsTransactionCount + 1;
      await _firestore.collection('users').doc(user.uid).update({
        'smsTransactionCount': newCount,
      });
      logDebug(
        'SMS transaction count updated: $newCount / $freeSmsTransactionLimit',
        tag: 'SmsService',
      );
    }

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
    final lowerBody = body.toLowerCase();

    // Direct check for strongest debit (Expense) indicators
    if (lowerBody.contains('debited from') ||
        lowerBody.contains('spent at') ||
        lowerBody.contains('paid for') ||
        lowerBody.contains('paid to') ||
        lowerBody.contains('sent to') ||
        lowerBody.contains('transferred to') ||
        lowerBody.contains('payment to') ||
        lowerBody.contains('withdraw at') ||
        lowerBody.contains('withdrawn from')) {
      return true;
    }

    // Direct check for strongest credit (Income) indicators
    if (lowerBody.contains('credited to') ||
        lowerBody.contains('received from') ||
        lowerBody.contains('deposited in') ||
        lowerBody.contains('added to') ||
        lowerBody.contains('refunded') ||
        lowerBody.contains('cashback received')) {
      return false;
    }

    // Fallback to keyword counts
    final debitCount = [
      'debited',
      'spent',
      'paid',
      'withdrawn',
      'debit',
      'payment',
      'transfer',
      'to',
      'purchase',
    ].where((kw) => lowerBody.contains(kw)).length;

    final creditCount = [
      'credited',
      'received',
      'credit',
      'deposit',
      'from',
      'in',
      'added',
      'refund',
      'cashback',
    ].where((kw) => lowerBody.contains(kw)).length;

    return debitCount >= creditCount;
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

    // Common Indian banks and labels
    final additionalMappings = {
      'pnb': 'Punjab National Bank',
      'axis': 'Axis Bank',
      'kotak': 'Kotak Bank',
      'icici': 'ICICI Bank',
      'hdfc': 'HDFC Bank',
      'sbi': 'State Bank of India',
      'boi': 'Bank of India',
      'bob': 'Bank of Baroda',
      'idbi': 'IDBI Bank',
      'unionb': 'Union Bank',
      'cbi': 'Central Bank of India',
      'indus': 'IndusInd Bank',
      'yesbnk': 'Yes Bank',
      'fdr': 'Federal Bank',
      'rbl': 'RBL Bank',
      'paytm': 'Paytm Bank',
      'airtel': 'Airtel Payments Bank',
      'jiopay': 'Jio Payments Bank',
    };

    for (final entry in additionalMappings.entries) {
      if (lowerAddress.contains(entry.key) || lowerBody.contains(entry.key)) {
        return entry.value;
      }
    }

    // Fallback: If no mapping matches, use the address/sender ID
    // Remove the prefix (like 'AD-') if present for a cleaner name
    String fallback = address.toUpperCase();
    if (fallback.contains('-')) {
      fallback = fallback.split('-').last;
    }
    return fallback;
  }

  String _extractMerchant(String body) {
    try {
      final merchantPatterns = [
        RegExp(r'at\s+([A-Za-z\s]+?)(?:\s|$|,)'),
        RegExp(r'from\s+([A-Za-z\s]+?)(?:\s|$|,)'),
        RegExp(r'to\s+([A-Za-z\s]+?)(?:\s|$|,)'),
      ];

      for (final pattern in merchantPatterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          final merchant = match.group(1);
          if (merchant != null && merchant.trim().isNotEmpty) {
            String cleaned = merchant.trim();
            // Clean up merchant name (remove unwanted suffixes like "Ref", "Txn", etc.)
            cleaned = cleaned.split(
              RegExp(r'\s+(?:Ref|Txn|ID|on|dated|at)\b', caseSensitive: false),
            )[0];
            return cleaned;
          }
        }
      }
    } catch (e) {
      logError('Merchant extraction failed', error: e);
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

    try {
      logDebug(
        'Triggering UI detection callback for amount: $amount',
        tag: 'SmsService',
      );
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
    } catch (e) {
      logError(
        'Error in transaction detection callback',
        error: e,
        tag: 'SmsService',
      );
    }
  }
}
