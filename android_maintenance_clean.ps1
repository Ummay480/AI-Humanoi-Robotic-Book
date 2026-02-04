# ANDROID BUILD MAINTENANCE SCRIPT
param(
    [ValidateSet("clean", "debug", "release", "verify", "doctor")]
    [string]$Command = "verify"
)

Write-Host "=== ANDROID BUILD MAINTENANCE ===" -ForegroundColor Cyan

# Set environment
$env:JAVA_HOME = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
cd "D:\AIDD\ai-humanoid-app\android"

switch ($Command) {
    "clean" {
        Write-Host "CLEANING build system..." -ForegroundColor Yellow
        .\gradlew --stop
        Remove-Item -Recurse -Force "build","app/build",".gradle" -ErrorAction SilentlyContinue
        Write-Host "Build cleaned" -ForegroundColor Green
    }

    "debug" {
        Write-Host "Building debug APK..." -ForegroundColor Cyan
        .\gradlew assembleDebug --no-daemon --stacktrace
        if ($LASTEXITCODE -eq 0) {
            $apk = Get-ChildItem "app\build\outputs\apk\debug\*.apk"
            Write-Host "Debug APK built - Count: $($apk.Count)" -ForegroundColor Green
        }
    }

    "release" {
        Write-Host "Building release AAB..." -ForegroundColor Magenta
        Write-Host "NOTE: Release build requires signing key" -ForegroundColor Yellow
        Write-Host "Create a keystore first, then run this command" -ForegroundColor White
        .\gradlew bundleRelease --no-daemon --stacktrace
        if ($LASTEXITCODE -eq 0) {
            $aab = Get-ChildItem "app\build\outputs\bundle\release\*.aab"
            Write-Host "Release AAB built - Count: $($aab.Count)" -ForegroundColor Green
        } else {
            Write-Host "Release build failed - missing signing key" -ForegroundColor Yellow
        }
    }

    "verify" {
        Write-Host "Verifying build environment..." -ForegroundColor Cyan
        java -version
        .\gradlew --version
        Write-Host "Environment verified" -ForegroundColor Green
    }

    "doctor" {
        Write-Host "Running Android Build Doctor..." -ForegroundColor Magenta

        # Check Java
        $java = java -version 2>&1 | Select-String "version"
        Write-Host "Java: $java"

        # Check Gradle
        $gradle = .\gradlew --version 2>&1 | Select-String "Gradle" | Select-Object -First 1
        Write-Host "Gradle: $gradle"

        # Check AndroidX
        if (Test-Path "gradle.properties") {
            $props = Get-Content "gradle.properties"
            $androidX = $props -match "android\.useAndroidX=true"
            Write-Host "AndroidX: $(if($androidX) {'Enabled'} else {'Disabled'})"
        }

        # Check build outputs
        $debugCount = (Get-ChildItem "app\build\outputs\apk\debug\*.apk" -ErrorAction SilentlyContinue).Count
        $releaseCount = (Get-ChildItem "app\build\outputs\bundle\release\*.aab" -ErrorAction SilentlyContinue).Count
        Write-Host "Debug APKs: $debugCount"
        Write-Host "Release AABs: $releaseCount"

        Write-Host "Build System Health Check Complete" -ForegroundColor Green
    }
}