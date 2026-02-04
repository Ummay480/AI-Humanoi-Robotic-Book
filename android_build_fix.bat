@echo off
echo === ANDROID BUILD FIX ===
echo Starting Android build fix process...

REM Change to android directory
cd android

echo.
echo 1. Stopping Gradle daemons...
call gradlew.bat --stop
if %ERRORLEVEL% EQU 0 (
    echo    ^> Gradle daemons stopped successfully
) else (
    echo    ^> Warning: Could not stop Gradle daemons
)

echo.
echo 2. Cleaning caches...
if exist .gradle rmdir /s /q .gradle
if exist build rmdir /s /q build
if exist app\build rmdir /s /q app\build
echo    ^> Cache directories cleaned

echo.
echo 3. Setting Java 21 path in gradle.properties...
echo org.gradle.java.home=C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot >> gradle.properties
echo org.gradle.java.installations.auto-detect=false >> gradle.properties
echo org.gradle.java.installations.auto-download=false >> gradle.properties
echo    ^> Java 21 path added to gradle.properties

echo.
echo 4. Updating app/build.gradle for Java 21 compatibility...
powershell -Command "(gc app\build.gradle) -replace 'sourceCompatibility JavaVersion.VERSION_17', 'sourceCompatibility JavaVersion.VERSION_21' | sc app\build.gradle"
powershell -Command "(gc app\build.gradle) -replace 'targetCompatibility JavaVersion.VERSION_17', 'targetCompatibility JavaVersion.VERSION_21' | sc app\build.gradle"
powershell -Command "(gc app\build.gradle) -replace 'jvmTarget = ''17''', 'jvmTarget = ''21''' | sc app\build.gradle"
echo    ^> Updated app/build.gradle for Java 21

echo.
echo 5. Setting environment variables...
set JAVA_HOME=C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%
echo    ^> Environment variables set

echo.
echo 6. Attempting build with --no-daemon flag...
call gradlew.bat assembleDebug --no-daemon --info
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ^> BUILD SUCCESSFUL!
    echo.
    echo Looking for APK file...
    dir app\build\outputs\apk\debug\*.apk 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo APK files found in app\build\outputs\apk\debug\
    ) else (
        echo.
        echo No APK files found in expected location
        echo Check app\build\outputs\apk\ for APK files
    )
) else (
    echo.
    echo ^> BUILD FAILED!
    echo.
    echo Check the output above for error details.
    echo You may need to run 'gradlew assembleDebug --info --stacktrace' manually for more details.
)

echo.
echo 7. Process completed. Check android directory for results.
pause