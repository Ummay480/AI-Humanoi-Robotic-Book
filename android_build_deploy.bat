@echo off
REM Batch wrapper for Android Build & Deploy PowerShell script
REM This enables execution of the PowerShell script with proper execution policy

echo =========================================
echo    ANDROID BUILD & DEPLOY ASSISTANT
echo =========================================
echo.

REM Run the PowerShell script with Bypass execution policy
powershell -ExecutionPolicy Bypass -File "%~dp0android_build_deploy.ps1" %*

echo.
echo Press any key to continue...
pause >nul