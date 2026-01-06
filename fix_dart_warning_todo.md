# Fix Dart BuildContext Mounted Warning

## Task
Fix the BuildContext mounting warning in `lib/screens/settings_screen.dart` around line 98.

## Problem
- [dart Information] Line 98: Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check.
- Guard a 'State.context' use with a 'mounted' check on the State, and other BuildContext use with a 'mounted' check on the BuildContext.

## Analysis
- Found multiple instances of incorrect `context.mounted` usage in async methods
- Need to replace `context.mounted` with `mounted` for State-related checks
- Need to properly guard ScaffoldMessenger.of(context) calls

## Steps
- [x] Analyze the current mounted checks in the file
- [x] Replace `context.mounted` checks with proper `mounted` checks on the State
- [x] Fix all async BuildContext usage patterns in _backupDatabase method
- [x] Fix all async BuildContext usage patterns in _restoreDatabase method
- [x] Test the changes compile without the specific mounting warning
- [x] Verify the functionality still works correctly

## Result
✅ Successfully fixed the BuildContext mounting warning. The flutter analyze command no longer shows the specific "Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check" warning mentioned in the task.
