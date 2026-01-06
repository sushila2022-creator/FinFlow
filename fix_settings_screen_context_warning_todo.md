# Settings Screen Context Warning Fix

## Problem
- Line 396: Don't use 'BuildContext's across async gaps in `_showBiometricSetupDialog()` method
- The method is async but uses `context` without proper mounted checks

## Solution Plan
- [ ] Add mounted checks in `_showBiometricSetupDialog()` method
- [ ] Add mounted checks in `_showSetPinDialog()` method  
- [ ] Ensure context is only used when widget is mounted
- [ ] Test the changes

## Files to Modify
- `lib/screens/settings_screen_fixed.dart`

## Expected Outcome
- Eliminate the BuildContext async gap warning
- Ensure safe context usage across async operations
- Maintain existing functionality
