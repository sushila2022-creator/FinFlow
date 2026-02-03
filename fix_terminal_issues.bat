@echo off
echo ==========================================
echo Fixing Terminal Problems for FinFlow App
echo ==========================================

echo.
echo 1. Enabling Developer Mode for Windows...
echo Please wait while we enable Developer Mode...
start ms-settings:developers
echo IMPORTANT: Please manually enable "Developer Mode" in the settings window that opened.
echo This is required for Flutter to build with plugins.

echo.
echo 2. Checking Flutter installation...

:: Check if flutter is in PATH
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Flutter found in PATH. Proceeding with commands...
) else (
    echo Flutter command not found in PATH.
    echo Please ensure Flutter SDK is installed and added to your system PATH.
    echo You can download Flutter from: https://flutter.dev/docs/get-started/install
    echo.
    echo If Flutter is installed but not in PATH, please add it manually:
    echo 1. Find your Flutter installation directory (e.g., C:\flutter)
    echo 2. Add it to your system PATH environment variable
    echo 3. Restart this terminal
    echo.
    pause
    exit /b 1
)

echo.
echo 3. Cleaning Flutter project...
flutter clean

echo.
echo 4. Getting dependencies...
flutter pub get

echo.
echo 5. Analyzing code for issues...
flutter analyze

echo.
echo 6. Checking Flutter doctor status...
flutter doctor

echo.
echo ==========================================
echo MANUAL STEPS REQUIRED:
echo ==========================================
echo 1. Enable Developer Mode in Windows Settings
echo 2. Restart your terminal/IDE after enabling Developer Mode
echo 3. Run: flutter build apk --debug
echo.
echo ==========================================
echo If issues persist after enabling Developer Mode:
echo ==========================================
echo 1. Ensure Android SDK is properly installed
echo 2. Check that JAVA_HOME is set correctly
echo 3. Verify Android Studio is installed and configured
echo 4. Make sure you have sufficient disk space
echo 5. If Flutter is not in PATH, add it manually:
echo    - Open System Properties > Environment Variables
echo    - Add Flutter bin directory to PATH (e.g., C:\flutter\bin)
echo    - Restart terminal
echo ==========================================

pause
