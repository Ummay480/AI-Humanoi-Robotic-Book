#!/usr/bin/env pwsh
# Quick Android Build Fix Script for ai-humanoid-app
# Cleans Gradle caches and builds debug APK with Java 21

Write-Host "=== QUICK ANDROID BUILD FIX ===" -ForegroundColor Blue
Write-Host "🔧 Starting Android build fix process..." -ForegroundColor Yellow

# Set Java 21 path
$java21Path = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
if (Test-Path "$java21Path\bin\java.exe") {
    Write-Host "✅ Java 21 found at: $java21Path" -ForegroundColor Green
    $env:JAVA_HOME = $java21Path
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
} else {
    Write-Host "❌ Java 21 not found at expected location!" -ForegroundColor Red
    Write-Host "Please install Java 21 from Eclipse Adoptium." -ForegroundColor Red
    exit 1
}

# Verify we're in the correct directory
if (-not (Test-Path "android")) {
    Write-Host "❌ android directory not found in current path!" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

Set-Location "android"

# Stop Gradle daemons
Write-Host "🧹 Stopping all Gradle daemons..." -ForegroundColor Cyan
try {
    .\gradlew.bat --stop --quiet
    Write-Host "✅ Stopped Gradle daemons" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not stop Gradle daemons: $_" -ForegroundColor Yellow
}

# Clean cache locations
Write-Host "🧹 Cleaning cache locations..." -ForegroundColor Cyan
$cacheLocations = @("$env:USERPROFILE\.gradle\", ".gradle\", "build\", "app\build\")

foreach ($location in $cacheLocations) {
    if (Test-Path $location) {
        try {
            Remove-Item -Path $location -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Removed: $location" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Could not remove $location`: $_" -ForegroundColor Yellow
        }
    }
}

# Update gradle.properties with Java 21 path
$gradlePropsPath = "gradle.properties"
if (Test-Path $gradlePropsPath) {
    $content = Get-Content $gradlePropsPath -Raw
    $javaHomeSetting = "org.gradle.java.home=$($java21Path.Replace('\', '\\'))"

    if ($content -match "^org.gradle.java.home=") {
        $content = $content -replace "^org.gradle.java.home=.*$", $javaHomeSetting
        Write-Host "✅ Updated existing Java home in gradle.properties" -ForegroundColor Green
    } else {
        $content += "`n$javaHomeSetting"
        Write-Host "✅ Added Java home to gradle.properties" -ForegroundColor Green
    }

    # Add other recommended properties
    if ($content -notmatch "org.gradle.java.installations.auto-detect") {
        $content += "`norg.gradle.java.installations.auto-detect=false"
        $content += "`norg.gradle.java.installations.auto-download=false"
    }

    Set-Content $gradlePropsPath $content
}

# Build debug APK
Write-Host "`n🏗️ Building debug APK..." -ForegroundColor Cyan
Write-Host "This may take 5-10 minutes..." -ForegroundColor Yellow

try {
    Write-Host "🔧 Running: ./gradlew clean assembleDebug --no-daemon --stacktrace" -ForegroundColor Cyan

    $buildResult = Start-Process -FilePath ".\gradlew.bat" -ArgumentList "clean", "assembleDebug", "--no-daemon", "--stacktrace" -NoNewWindow -Wait -PassThru

    if ($buildResult.ExitCode -eq 0) {
        Write-Host "✅ BUILD SUCCESSFUL!" -ForegroundColor Green

        # Look for APK file
        $apkFiles = Get-ChildItem -Path "app\build\outputs\apk\debug" -Filter "*.apk" -ErrorAction SilentlyContinue
        if ($apkFiles) {
            foreach ($apk in $apkFiles) {
                $sizeMB = [math]::Round($apk.Length / 1MB, 2)
                Write-Host "📱 APK: $($apk.Name) ($sizeMB MB)" -ForegroundColor Green
                Write-Host "   Location: $($apk.FullName)" -ForegroundColor Green
            }
        } else {
            Write-Host "⚠️ APK file not found in expected location" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ BUILD FAILED with exit code: $($buildResult.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ BUILD PROCESS ERROR: $_" -ForegroundColor Red
}

Write-Host "`n🎉 Process completed!" -ForegroundColor Green