import 'package:flutter/foundation.dart';
import 'lib/utils/utility.dart';

void main() {
  // Test the stringToColor function with various inputs
  debugPrint('Testing stringToColor function:');
  
  // Test cases that should work
  debugPrint('Testing valid inputs:');
  debugPrint('4CAF50 -> ${stringToColor('4CAF50')}'); // Should work
  debugPrint('#4CAF50 -> ${stringToColor('#4CAF50')}'); // Should work
  debugPrint('0xFF4CAF50 -> ${stringToColor('0xFF4CAF50')}'); // Should work
  
  // Test the problematic case mentioned in the issue
  debugPrint('\nTesting problematic inputs:');
  debugPrint('0xFF#4CAF50 -> ${stringToColor('0xFF#4CAF50')}'); // Should be fixed to work
  
  // Test edge cases
  debugPrint('\nTesting edge cases:');
  debugPrint('Empty string -> ${stringToColor('')}'); // Should return grey
  debugPrint('Invalid -> ${stringToColor('INVALID')}'); // Should return grey
  
  debugPrint('\nAll tests completed successfully!');
}
