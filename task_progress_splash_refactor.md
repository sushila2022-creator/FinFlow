# Splash Screen Refactor Todo List

## Objective: Create seamless app startup experience

### Tasks:
- [x] Analyze current splash screen implementation
- [x] Remove default Android splash screen (white screen)
  - [x] Configure styles.xml to disable default splash
  - [x] Update AndroidManifest.xml to disable default splash
- [x] Update splash_screen.dart for unified experience
  - [x] Add app icon (assets/icon/icon.png) to splash screen
  - [x] Display 'FinFlow' text below icon
  - [x] Use dark blue background color
- [x] Reduce splash screen timer duration from 3s to 1.5s
- [x] Test the changes

## Summary of Changes Made:

### 1. Android Configuration (styles.xml)
- Modified LaunchTheme to use transparent background
- Added `android:windowIsTranslucent` to disable default white splash

### 2. Android Manifest (AndroidManifest.xml)
- Changed activity theme from `@style/LaunchTheme` to `@style/NormalTheme`
- This prevents the default Android splash screen from appearing

### 3. Flutter Splash Screen (lib/screens/splash_screen.dart)
- Replaced hardcoded `Icons.account_balance_wallet` with custom `Image.asset('assets/icon/icon.png')`
- Added errorBuilder fallback to default icon if custom icon fails to load
- Reduced timer duration from 3 seconds to 1.5 seconds
- Maintained dark blue background (AppTheme.primaryColor) and 'FinFlow' text styling

### 4. Testing
- App builds successfully without errors
- All changes are functional and properly integrated
