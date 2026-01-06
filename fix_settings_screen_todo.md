# Fix Settings Screen Deprecated Value Warning

## Task Overview
Fix the deprecated `value` property warning in DropdownButtonFormField at line 269 in settings_screen_fixed.dart

## Steps
- [ ] Analyze the current DropdownButtonFormField implementation
- [ ] Replace deprecated `value` parameter with `initialValue`
- [ ] Verify the fix maintains the same functionality
- [ ] Test that the currency selection still works correctly

## Technical Details
- File: lib/screens/settings_screen_fixed.dart
- Line: 269 (approximately)
- Issue: `value: currencyProvider.currentCurrencySymbol` is deprecated
- Fix: Replace with `initialValue: currencyProvider.currentCurrencySymbol`
- Widget: DropdownButtonFormField<String>
