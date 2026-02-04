@echo off
echo Setting up Java 21 and running Android build fix...

REM Set Java Home
set JAVA_HOME=C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%

REM Navigate to Android directory
cd /d "D:\AIDD\ai-humanoid-app\android"

REM Stop Gradle daemons
echo Stopping Gradle daemons...
gradlew.bat --stop

REM Clean caches
echo Cleaning Gradle caches...
rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
rmdir /s /q "build" 2>nul
rmdir /s /q ".gradle" 2>nul
rmdir /s /q "app\build" 2>nul

REM Clean build
echo Running clean build...
gradlew.bat clean assembleDebug --no-daemon --stacktrace

echo Build process completed. Check the output above for any errors.
pause