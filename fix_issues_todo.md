# Fix Issues Todo List

## Task: Fix Flutter Finance Tracker Issues

### Issues to Fix:
1. **Backup Database Error**: Fix 'Backup failed: Database file not found' by ensuring backup logic uses getDatabasesPath() with exact filename from DatabaseHelper
2. **Storage Permission Error**: Replace permission requests with share_plus package to export files without 'Storage permission denied' errors
3. **Settings Screen Overflow**: Wrap Settings screen body in SingleChildScrollView to resolve bottom overflow

### Implementation Steps:
- [ ] 1. Analyze current backup/export logic and DatabaseHelper implementation
- [ ] 2. Identify the exact database filename used in DatabaseHelper
- [ ] 3. Update backup logic to use getDatabasesPath() with correct filename
- [ ] 4. Replace storage permission requests with share_plus package
- [ ] 5. Test backup functionality to ensure database file is found
- [ ] 6. Analyze Settings screen layout and identify overflow issues
- [ ] 7. Wrap Settings screen body in SingleChildScrollView
- [ ] 8. Test all fixes to ensure they work correctly
- [ ] 9. Verify no new issues were introduced

### Files to Examine:
- lib/utils/database_helper.dart
- lib/screens/settings_screen.dart
- pubspec.yaml (check for share_plus dependency)
- Any backup/export related services

### Success Criteria:
- Backup functionality works without 'Database file not found' errors
- File export works without storage permission errors
- Settings screen renders without bottom overflow
- All existing functionality remains intact
