# Restore Year Filter Button - Todo List

## Task Overview
Add the missing 'Year' filter option to the dashboard screen tabs to show: Today | Week | Month | Year

## Implementation Steps

- [x] 1. Update `_selectedTabIndex` comment to include Year (0: Today, 1: Week, 2: Month, 3: Year)
- [x] 2. Add Year filter logic to `_getFilteredTransactions` method (case 3)
- [x] 3. Add 'Year' pill chip to the UI tabs row
- [x] 4. Ensure the 4 tabs fit properly in the row (use SingleChildScrollView if needed)
- [x] 5. Test the implementation to ensure no crashes occur

## Technical Details
- Current tabs: ['Today', 'Week', 'Month']
- Target tabs: ['Today', 'Week', 'Month', 'Year']
- Year filter shows transactions for the current calendar year
- UI remains responsive and properly styled with horizontal scrolling

## Files Modified
- `lib/screens/dashboard_screen.dart`

## Changes Made
1. **Updated comment**: `_selectedTabIndex` now includes Year (3) in the documentation
2. **Added Year filter logic**: Case 3 in `_getFilteredTransactions` filters by `tx.date.year == now.year`
3. **Added Year pill chip**: 4th filter button with proper selection logic
4. **Enhanced UI layout**: Wrapped tabs in `SingleChildScrollView` with horizontal scrolling for better fit

## Success Criteria - ✅ COMPLETED
- All 4 filter buttons are visible and functional
- Year filter correctly shows transactions from the current year
- No crashes or UI issues when switching between filters
- Tabs are properly arranged with horizontal scrolling for 4th button
