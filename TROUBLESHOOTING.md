# FinFlow App - Terminal Problems Fix Guide

## Overview
This guide helps resolve common terminal problems when building the FinFlow Flutter application.

## Critical Issue: Developer Mode Not Enabled

### Problem
```
Building with plugins requires symlink support.
Please enable Developer Mode in your system settings.
```

### Solution
1. **Open Windows Settings:**
   - Press `Win + I` or search for "Settings"
   - Go to "Privacy & Security" → "For developers"

2. **Enable Developer Mode:**
   - Toggle "Developer Mode" to ON
   - Confirm any prompts that appear

3. **Alternative method:**
   - Open Command Prompt as Administrator
   - Run: `start ms-settings:developers`
   - Enable Developer Mode in the settings window

4. **Restart your terminal/IDE** after enabling Developer Mode

## Common Terminal Errors and Solutions

### 1. Build Failures
```bash
# After enabling Developer Mode:
flutter clean
flutter pub get
flutter build apk --debug
```

### 2. Dependency Issues
```bash
# Update dependencies if needed:
flutter pub upgrade
flutter pub outdated
```

### 3. Android SDK Issues
```bash
# Check Android SDK status:
flutter doctor --android-licenses
flutter doctor
```

### 4. Java/Gradle Issues
- Ensure Android Studio is installed
- Check JAVA_HOME environment variable
- Verify Gradle is properly configured

## Quick Fix Script

Run the provided `fix_terminal_issues.bat` script:
```bash
# Double-click fix_terminal_issues.bat
# OR run in command prompt:
.\fix_terminal_issues.bat
```

## Manual Verification Steps

1. **Check Flutter Status:**
   ```bash
   flutter doctor
   ```

2. **Clean and Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

3. **Test App Run:**
   ```bash
   flutter run
   ```

## If Problems Persist

1. **Check Disk Space:** Ensure you have at least 2GB free space
2. **Restart Computer:** After enabling Developer Mode
3. **Update Flutter:** `flutter upgrade`
4. **Reinstall Dependencies:** Delete `pubspec.lock` and run `flutter pub get`

## Contact Support

If you continue to experience issues:
1. Run `flutter doctor -v` for detailed diagnostics
2. Check the Flutter logs in your project directory
3. Review the error messages carefully
4. Ensure all prerequisites are met (Android SDK, Java, etc.)