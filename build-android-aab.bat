@echo off
REM Batch script for building Android release AAB

echo Starting Android release build for AI Humanoid App...

REM Navigate to project directory
cd /d "%~dp0"

REM Sync Capacitor with Android
echo Syncing Capacitor with Android...
npx cap sync android

REM Navigate to Android directory
cd android

REM Build the release AAB
echo Building release AAB...
gradlew.bat bundleRelease

echo Build completed!
echo Find your AAB file at: %CD%\app\build\outputs\bundle\release\app-release.aab

REM Optional: Open the output directory
start "" "%CD%\app\build\outputs\bundle\release\"

pause