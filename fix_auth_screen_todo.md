# Fix AuthScreen Dart Warning - Todo List

## Task: Fix Dart warning about 'key' parameter in AuthScreen

### Steps:
- [ ] Analyze the current AuthScreen implementation
- [ ] Convert 'key' parameter to super parameter as suggested by Dart analyzer
- [ ] Verify the fix compiles correctly
- [ ] Test the application to ensure functionality remains intact

### Issue Details:
- File: lib/screens/auth/auth_screen.dart
- Line: 8
- Warning: Parameter 'key' could be a super parameter
- Solution: Use `super.key` instead of explicit `key` parameter and `super(key: key)`
