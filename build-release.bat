@echo off
echo ========================================
echo FinFlow Release Build Script
echo ========================================
echo.

set /p STORE_PASSWORD="Enter keystore store password: "
set /p KEY_PASSWORD="Enter key password: "
echo.
echo Building release bundle...
echo.

flutter build appbundle --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo The .aab file is located at:
    echo build\app\outputs\bundle\release\app-release.aab
    echo.
) else (
    echo.
    echo ========================================
    echo BUILD FAILED
    echo ========================================
    echo.
    echo Please check the error messages above.
    echo Make sure you entered the correct passwords.
    echo.
)

pause