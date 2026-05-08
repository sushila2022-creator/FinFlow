import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:finflow/services/sms_service.dart';
import 'package:finflow/services/notification_service.dart';
import 'package:finflow/utils/debug_logger.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SmsService _smsService = SmsService();
  final NotificationService _notificationService = NotificationService();
  
  bool _isSmsScanEnabled = false;
  bool _dailyReminderEnabled = true;
  bool _isAppLockEnabled = false;
  bool _isInitialized = false;
  bool _isSyncing = false;
  
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  bool get isSmsScanEnabled => _isSmsScanEnabled;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get isInitialized => _isInitialized;

  SettingsProvider() {
    _loadLocalSettings().then((_) {
      _authStateSubscription = _auth.authStateChanges().listen((user) {
        if (user != null) {
          _startFirestoreSync(user);
        } else {
          _stopFirestoreSync();
        }
      });
    });
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSmsScanEnabled = prefs.getBool('smart_sms_scan_enabled') ?? false;
    _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
    _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
    
    _isInitialized = true;
    _applySettings();
    notifyListeners();
  }

  void _applySettings() {
    if (_isSmsScanEnabled) {
      _smsService.startScanning();
    } else {
      _smsService.stopScanning();
    }

    if (_dailyReminderEnabled) {
      _notificationService.scheduleDailyReminder(9, 0);
    } else {
      _notificationService.cancelDailyReminder();
    }
  }

  void _startFirestoreSync(User user) {
    _settingsSubscription?.cancel();
    _settingsSubscription = _firestore
        .collection('settings')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      if (_isSyncing) return;

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final remoteTimestamp = (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        
        final prefs = await SharedPreferences.getInstance();
        final localTimestamp = prefs.getInt('settings_updated_at') ?? 0;

        if (remoteTimestamp > localTimestamp) {
          logDebug('Remote settings are newer, updating local...', tag: 'SettingsProvider');
          _isSmsScanEnabled = data['smart_sms_scan_enabled'] ?? _isSmsScanEnabled;
          _dailyReminderEnabled = data['daily_reminder_enabled'] ?? _dailyReminderEnabled;
          _isAppLockEnabled = data['app_lock_enabled'] ?? _isAppLockEnabled;
          
          await prefs.setBool('smart_sms_scan_enabled', _isSmsScanEnabled);
          await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
          await prefs.setBool('app_lock_enabled', _isAppLockEnabled);
          await prefs.setInt('settings_updated_at', remoteTimestamp);
          
          _applySettings();
          notifyListeners();
        } else if (remoteTimestamp < localTimestamp) {
          logDebug('Local settings are newer, uploading to Firestore...', tag: 'SettingsProvider');
          _uploadSettings();
        }
      } else {
        logDebug('No remote settings found, uploading current local settings...', tag: 'SettingsProvider');
        _uploadSettings();
      }
    }, onError: (e) {
      logError('Settings sync failed', tag: 'SettingsProvider', error: e);
    });
  }

  void _stopFirestoreSync() {
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
  }

  Future<void> _uploadSettings() async {
    final user = _auth.currentUser;
    if (user == null || _isSyncing) return;

    _isSyncing = true;
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('settings').doc(user.uid).set({
        'smart_sms_scan_enabled': _isSmsScanEnabled,
        'daily_reminder_enabled': _dailyReminderEnabled,
        'app_lock_enabled': _isAppLockEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('settings_updated_at', timestamp);
    } catch (e) {
      logError('Failed to upload settings', tag: 'SettingsProvider', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> setSmsScanEnabled(bool value) async {
    _isSmsScanEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_sms_scan_enabled', value);
    await prefs.setInt('settings_updated_at', DateTime.now().millisecondsSinceEpoch);
    
    bool success = true;
    if (value) {
      success = await _smsService.startScanning();
      if (!success) {
        _isSmsScanEnabled = false;
        await prefs.setBool('smart_sms_scan_enabled', false);
      }
    } else {
      _smsService.stopScanning();
    }
    
    _uploadSettings();
    notifyListeners();
    return success;
  }

  Future<bool> setDailyReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    
    bool granted = true;
    if (value) {
      granted = await _notificationService.requestPermission();
    }

    if (granted) {
      _dailyReminderEnabled = value;
      await prefs.setBool('daily_reminder_enabled', value);
      await prefs.setInt('settings_updated_at', DateTime.now().millisecondsSinceEpoch);
      
      if (value) {
        _notificationService.scheduleDailyReminder(9, 0);
      } else {
        _notificationService.cancelDailyReminder();
      }
      _uploadSettings();
    } else {
      return false;
    }
    
    notifyListeners();
    return true;
  }

  Future<void> setAppLockEnabled(bool value) async {
    _isAppLockEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', value);
    await prefs.setInt('settings_updated_at', DateTime.now().millisecondsSinceEpoch);
    
    _uploadSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
