@echo off
REM Batch wrapper for the Android build fix PowerShell script
REM This allows running the script from command prompt or other environments

echo ===============================================
echo    ANDROID BUILD FIX - BATCH WRAPPER
echo ===============================================

REM Check if running with elevated privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
) else (
    echo WARNING: Not running as administrator. Some cleanup operations might fail.
)

REM Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available. Please install PowerShell.
    pause
    exit /b 1
)

REM Run the PowerShell script with passed arguments
powershell -ExecutionPolicy Bypass -File "%~dp0fix_android_build.ps1" %*

REM Check the exit code from PowerShell
if %errorlevel% neq 0 (
    echo Build fix process failed with exit code: %errorlevel%
    pause
    exit /b %errorlevel%
) else (
    echo Build fix process completed successfully!
)

pause