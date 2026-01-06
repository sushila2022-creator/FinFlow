@echo off
cd /d "c:\Users\ratan\Desktop\my_first_app\daily_finance_tracker"
powershell -Command "(Get-Content lib\screens\settings_screen_fixed.dart) -replace 'await currentDb\?\.close\(\);', 'await currentDb.close();' | Set-Content lib\screens\settings_screen_fixed.dart"
echo Fix completed!
pause
