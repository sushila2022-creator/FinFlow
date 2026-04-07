/// Debug logger utility for FinFlow
///
/// This utility provides a centralized way to control debug output.
/// Set [isDebugMode] to false for production builds to disable all debug output.
library;

import 'package:flutter/foundation.dart';

/// Toggle debug mode - set to false for production
/// By default, uses kDebugMode from Flutter foundation
const bool isDebugMode = kDebugMode;

/// Logs a debug message if debug mode is enabled
/// In production (isDebugMode = false), this does nothing
void logDebug(String message, {String? tag}) {
  if (isDebugMode) {
    if (tag != null) {
      debugPrint('[$tag] $message');
    } else {
      debugPrint(message);
    }
  }
}

/// Logs an error message if debug mode is enabled
/// In production, errors are still logged using debugPrint for critical issues
void logError(String message, {String? tag, dynamic error}) {
  if (isDebugMode) {
    final prefix = tag != null ? '[$tag]' : '[Error]';
    debugPrint('$prefix $message${error != null ? ': $error' : ''}');
  }
}

/// Logs a warning message if debug mode is enabled
void logWarning(String message, {String? tag}) {
  if (isDebugMode) {
    final prefix = tag != null ? '[$tag]' : '[Warning]';
    debugPrint('$prefix $message');
  }
}
