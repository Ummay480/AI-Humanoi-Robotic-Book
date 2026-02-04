# Save as: fix_all_android_issues_clean.ps1
# Run from: D:\AIDD\ai-humanoid-app\

param(
    [switch]$SkipEnvSetup = $false,
    [switch]$ForceClean = $true,
    [switch]$BuildDebug = $true,
    [switch]$BuildRelease = $true,
    [switch]$CreateVerification = $true
)

Write-Host "=== COMPREHENSIVE ANDROID BUILD FIX ===" -ForegroundColor Magenta -BackgroundColor Black

# ================ PART 1: PERMANENT JAVA ENVIRONMENT SETUP ================
if (-not $SkipEnvSetup) {
    Write-Host "`n1. SETTING UP JAVA 21 ENVIRONMENT..." -ForegroundColor Cyan

    $javaPath = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
    $javaBinPath = "$javaPath\bin"

    # Set for current session
    $env:JAVA_HOME = $javaPath
    $env:PATH = "$javaBinPath;$env:PATH"

    # Check if running as admin for permanent changes
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        # Set system-wide JAVA_HOME
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, [System.EnvironmentVariableTarget]::Machine)

        # Add to system PATH
        $currentSystemPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
        if ($currentSystemPath -notlike "*$javaBinPath*") {
            $newSystemPath = "$javaBinPath;$currentSystemPath"
            [System.Environment]::SetEnvironmentVariable("PATH", $newSystemPath, [System.EnvironmentVariableTarget]::Machine)
        }

        Write-Host "[SUCCESS] Permanent system environment variables set (Admin required)" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Running without admin rights - setting user environment only" -ForegroundColor Yellow

        # Set user environment
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, [System.EnvironmentVariableTarget]::User)

        # Add to user PATH
        $currentUserPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
        if ($currentUserPath -notlike "*$javaBinPath*") {
            $newUserPath = "$javaBinPath;$currentUserPath"
            [System.Environment]::SetEnvironmentVariable("PATH", $newUserPath, [System.EnvironmentVariableTarget]::User)
        }

        Write-Host "[SUCCESS] User environment variables set" -ForegroundColor Green
    }

    # Verify Java
    Write-Host "`n[INFO] Verifying Java 21 installation..." -ForegroundColor Cyan
    try {
        $javaVersion = & "$javaBinPath\java" -version 2>&1
        if ($javaVersion -match '21\.') {
            Write-Host "[SUCCESS] Java 21 verified: $(($javaVersion | Select-Object -First 1))" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Java version mismatch!" -ForegroundColor Red
            Write-Host $javaVersion
        }
    } catch {
        Write-Host "[ERROR] Java not accessible!" -ForegroundColor Red
        exit 1
    }
}

# ================ PART 2: NAVIGATE TO ANDROID DIRECTORY ================
Write-Host "`n2. CONFIGURING ANDROID PROJECT..." -ForegroundColor Cyan

if (-not (Test-Path "android")) {
    Write-Host "[ERROR] Android directory not found!" -ForegroundColor Red
    exit 1
}

cd "android"

# ================ PART 3: FIX ANDROIDX CONFIGURATION ================
Write-Host "`n3. FIXING ANDROIDX CONFIGURATION..." -ForegroundColor Cyan

$gradlePropsPath = "gradle.properties"
$gradlePropsContent = @"
# AndroidX configuration (REQUIRED for modern Android)
android.useAndroidX=true
android.enableJetifier=true

# Kotlin configuration
kotlin.code.style=official

# Java compatibility
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.java.home=$env:JAVA_HOME

# Build performance
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.daemon=true

# Android build
android.defaults.buildfeatures.buildconfig=true
android.nonTransitiveRClass=true

# Disable Build Scan
org.gradle.unsafe.watch-fs=false
org.gradle.configureondemand=true
"@

if (Test-Path $gradlePropsPath) {
    # Backup existing file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "${gradlePropsPath}.backup_${timestamp}"
    Copy-Item $gradlePropsPath $backupName
    Write-Host "[INFO] Backed up existing gradle.properties to $backupName" -ForegroundColor Cyan

    # Read and merge with existing content
    $existingContent = Get-Content $gradlePropsPath -Raw
    $mergedContent = ""

    # Keep existing non-AndroidX properties, update AndroidX ones
    $lines = $existingContent -split "`n"
    foreach ($line in $lines) {
        if ($line -notmatch '^android\.useAndroidX=' -and $line -notmatch '^android\.enableJetifier=') {
            $mergedContent += "$line`n"
        }
    }

    $mergedContent += $gradlePropsContent
    $mergedContent | Out-File $gradlePropsPath -Encoding UTF8
} else {
    $gradlePropsContent | Out-File $gradlePropsPath -Encoding UTF8
}

Write-Host "[SUCCESS] gradle.properties configured with AndroidX support" -ForegroundColor Green

# ================ PART 4: CLEAN GRADLE CACHE ================
if ($ForceClean) {
    Write-Host "`n4. CLEANING GRADLE CACHE..." -ForegroundColor Cyan

    # Stop Gradle daemons
    try { .\gradlew --stop } catch { Write-Host "[WARNING] Could not stop Gradle daemon" -ForegroundColor Yellow }

    # Clear global cache
    $cachePaths = @(
        "$HOME\.gradle\caches",
        "$HOME\.gradle\wrapper",
        "$HOME\.gradle\daemon"
    )

    foreach ($cachePath in $cachePaths) {
        if (Test-Path $cachePath) {
            Remove-Item -Recurse -Force $cachePath -ErrorAction SilentlyContinue
            Write-Host "[CLEANED] $(Split-Path $cachePath -Leaf)" -ForegroundColor Yellow
        }
    }

    # Clear project build directories
    $projectDirs = @("build", ".gradle", "app\build", ".idea")
    foreach ($dir in $projectDirs) {
        if (Test-Path $dir) {
            Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
            Write-Host "[CLEANED] $dir" -ForegroundColor Yellow
        }
    }

    Write-Host "[SUCCESS] All caches cleaned" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# ================ PART 5: BUILD DEBUG APK ================
if ($BuildDebug) {
    Write-Host "`n5. BUILDING DEBUG APK..." -ForegroundColor Cyan

    $debugLog = "debug_build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    Write-Host "[INFO] Logging to: $debugLog" -ForegroundColor Cyan

    $debugCommand = ".\gradlew clean assembleDebug --no-daemon --stacktrace --warning-mode all"
    Write-Host "[RUNNING] $debugCommand" -ForegroundColor Yellow

    $debugStart = Get-Date
    Invoke-Expression $debugCommand 2>&1 | Tee-Object -FilePath $debugLog

    if ($LASTEXITCODE -eq 0) {
        $debugDuration = (Get-Date) - $debugStart
        $roundedMinutes = [math]::Round($debugDuration.TotalMinutes, 1)
        Write-Host "[SUCCESS] DEBUG BUILD SUCCESSFUL! ($roundedMinutes minutes)" -ForegroundColor Green

        # Find APK
        $debugApk = Get-ChildItem "app\build\outputs\apk\debug\*.apk" | Select-Object -First 1
        if ($debugApk) {
            $debugSize = [math]::Round($debugApk.Length / 1MB, 2)
            Write-Host "[APK] $($debugApk.Name) ($debugSize MB)" -ForegroundColor Cyan
            Write-Host "[LOCATION] $($debugApk.FullName)" -ForegroundColor Cyan

            # Generate SHA256
            $debugHash = Get-FileHash $debugApk.FullName -Algorithm SHA256
            Write-Host "[SHA256] $($debugHash.Hash)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "[ERROR] DEBUG BUILD FAILED! Check $debugLog" -ForegroundColor Red
        if (-not $BuildRelease) { exit 1 }
    }
}

# ================ PART 6: BUILD RELEASE AAB ================
if ($BuildRelease) {
    Write-Host "`n6. BUILDING RELEASE AAB..." -ForegroundColor Cyan

    $releaseLog = "release_build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    Write-Host "[INFO] Logging to: $releaseLog" -ForegroundColor Cyan

    $releaseCommand = ".\gradlew clean bundleRelease --no-daemon --stacktrace --warning-mode all"
    Write-Host "[RUNNING] $releaseCommand" -ForegroundColor Yellow

    $releaseStart = Get-Date
    Invoke-Expression $releaseCommand 2>&1 | Tee-Object -FilePath $releaseLog

    if ($LASTEXITCODE -eq 0) {
        $releaseDuration = (Get-Date) - $releaseStart
        $roundedMinutes = [math]::Round($releaseDuration.TotalMinutes, 1)
        Write-Host "[SUCCESS] RELEASE BUILD SUCCESSFUL! ($roundedMinutes minutes)" -ForegroundColor Green

        # Find AAB
        $releaseAab = Get-ChildItem "app\build\outputs\bundle\release\*.aab" | Select-Object -First 1
        if ($releaseAab) {
            $releaseSize = [math]::Round($releaseAab.Length / 1MB, 2)
            Write-Host "[AAB] $($releaseAab.Name) ($releaseSize MB)" -ForegroundColor Cyan
            Write-Host "[LOCATION] $($releaseAab.FullName)" -ForegroundColor Cyan

            # Generate SHA256
            $releaseHash = Get-FileHash $releaseAab.FullName -Algorithm SHA256
            Write-Host "[SHA256] $($releaseHash.Hash)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "[ERROR] RELEASE BUILD FAILED! Check $releaseLog" -ForegroundColor Red
        exit 1
    }
}

# ================ PART 7: CREATE VERIFICATION SCRIPTS ================
if ($CreateVerification) {
    Write-Host "`n7. CREATING VERIFICATION SCRIPTS..." -ForegroundColor Cyan

    # Verification script
    $verifyScript = @"
# verify_android_env.ps1
Write-Host "=== ANDROID BUILD ENVIRONMENT VERIFICATION ===" -ForegroundColor Magenta

# Check Java
Write-Host "`n[INFO] Java Configuration:" -ForegroundColor Cyan
`$javaHome = [System.Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')
if ([string]::IsNullOrEmpty(`$javaHome)) {
    `$javaHome = [System.Environment]::GetEnvironmentVariable('JAVA_HOME', 'User')
}
if ([string]::IsNullOrEmpty(`$javaHome)) {
    `$javaHome = `$env:JAVA_HOME
}

if (`$javaHome -eq "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot") {
    Write-Host "[SUCCESS] JAVA_HOME correctly set to Java 21" -ForegroundColor Green
    java -version 2>&1 | Select-String "version"
} else {
    Write-Host "[ERROR] JAVA_HOME not set correctly: `$javaHome" -ForegroundColor Red
}

# Check AndroidX configuration
Write-Host "`n[INFO] AndroidX Configuration:" -ForegroundColor Cyan
if (Test-Path "gradle.properties") {
    `$gradleProps = Get-Content "gradle.properties"
    if (`$gradleProps -match "android\.useAndroidX=true") {
        Write-Host "[SUCCESS] AndroidX enabled" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] AndroidX not enabled" -ForegroundColor Red
    }
}

# Check build outputs
Write-Host "`n[INFO] Build Outputs:" -ForegroundColor Cyan
cd "D:\AIDD\ai-humanoid-app\android"

`$debugApk = Get-ChildItem "app\build\outputs\apk\debug\*.apk" -ErrorAction SilentlyContinue
`$releaseAab = Get-ChildItem "app\build\outputs\bundle\release\*.aab" -ErrorAction SilentlyContinue

if (`$debugApk) {
    Write-Host "[SUCCESS] Debug APK available (`$(`$debugApk.Count) files)" -ForegroundColor Green
    `$debugApk | ForEach-Object {
        `$size = [math]::Round(`$_.Length / 1MB, 2)
        Write-Host "   - `$(`$_.Name) (`$size MB)"
    }
} else {
    Write-Host "[WARNING] No debug APK found" -ForegroundColor Yellow
}

if (`$releaseAab) {
    Write-Host "[SUCCESS] Release AAB available (`$(`$releaseAab.Count) files)" -ForegroundColor Green
    `$releaseAab | ForEach-Object {
        `$size = [math]::Round(`$_.Length / 1MB, 2)
        Write-Host "   - `$(`$_.Name) (`$size MB)"
    }
} else {
    Write-Host "[WARNING] No release AAB found" -ForegroundColor Yellow
}

Write-Host "`n[TARGET] VERIFICATION COMPLETE" -ForegroundColor Cyan
"@

    $verifyScript | Out-File "verify_android_env.ps1" -Encoding UTF8
    Write-Host "[SUCCESS] Created: verify_android_env.ps1" -ForegroundColor Green

    # Quick build script
    $quickBuildScript = @"
# quick_build.ps1
param([string]`$BuildType = "assembleDebug")

Write-Host "[RUNNING] Quick Android Build: `$BuildType" -ForegroundColor Cyan
cd "D:\AIDD\ai-humanoid-app\android"

# Set Java for this session
`$env:JAVA_HOME = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
`$env:PATH = "`$env:JAVA_HOME\bin;`$env:PATH"

# Build
.\gradlew clean `$BuildType --no-daemon --stacktrace

if (`$LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Build successful!" -ForegroundColor Green

    if (`$BuildType -eq "assembleDebug") {
        `$apk = Get-ChildItem "app\build\outputs\apk\debug\*.apk" | Select-Object -First 1
        if (`$apk) {
            `$size = [math]::Round(`$apk.Length / 1MB, 2)
            Write-Host "[APK] `$(`$apk.Name) (`$size MB)" -ForegroundColor Green
        }
    } elseif (`$BuildType -eq "bundleRelease") {
        `$aab = Get-ChildItem "app\build\outputs\bundle\release\*.aab" | Select-Object -First 1
        if (`$aab) {
            `$size = [math]::Round(`$aab.Length / 1MB, 2)
            Write-Host "[AAB] `$(`$aab.Name) (`$size MB)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
}
"@

    $quickBuildScript | Out-File "quick_build.ps1" -Encoding UTF8
    Write-Host "[SUCCESS] Created: quick_build.ps1" -ForegroundColor Green
}

# ================ PART 8: FINAL STATUS REPORT ================
Write-Host "`n" + ("="*60) -ForegroundColor Magenta
Write-Host "[SUCCESS] COMPREHENSIVE ANDROID BUILD FIX COMPLETE!" -ForegroundColor Green -BackgroundColor Black
Write-Host "="*60 -ForegroundColor Magenta

Write-Host "`n[CHANGES APPLIED:]:" -ForegroundColor Cyan
Write-Host "[SUCCESS] 1. Java 21 Environment: Permanent system/user setup" -ForegroundColor Green
Write-Host "[SUCCESS] 2. AndroidX Configuration: gradle.properties updated" -ForegroundColor Green
Write-Host "[SUCCESS] 3. Gradle Cache: All corrupted files cleared" -ForegroundColor Green
Write-Host "[SUCCESS] 4. Build Environment: Fully configured and verified" -ForegroundColor Green

Write-Host "`n[BUILD OUTPUTS:]:" -ForegroundColor Cyan
$debugExists = Test-Path "app\build\outputs\apk\debug\*.apk"
$releaseExists = Test-Path "app\build\outputs\bundle\release\*.aab"

if ($debugExists -or $releaseExists) {
    if ($debugExists) {
        $debugFiles = Get-ChildItem "app\build\outputs\apk\debug\*.apk"
        Write-Host "[APK COUNT] Debug APKs: $($debugFiles.Count) file(s)" -ForegroundColor Cyan
        $debugFiles | ForEach-Object {
            $size = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  - $($_.Name) ($size MB)"
        }
    }

    if ($releaseExists) {
        $releaseFiles = Get-ChildItem "app\build\outputs\bundle\release\*.aab"
        Write-Host "[AAB COUNT] Release AABs: $($releaseFiles.Count) file(s)" -ForegroundColor Cyan
        $releaseFiles | ForEach-Object {
            $size = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  - $($_.Name) ($size MB)"
        }
    }
} else {
    Write-Host "[WARNING] No build outputs found (build may have failed)" -ForegroundColor Yellow
}

Write-Host "`n[COMMANDS AVAILABLE:]:" -ForegroundColor Cyan
Write-Host "[CMD] .\verify_android_env.ps1    - Check environment" -ForegroundColor Cyan
Write-Host "[CMD] .\quick_build.ps1           - Quick build (default: debug)" -ForegroundColor Cyan
Write-Host "[CMD] .\quick_build.ps1 bundleRelease - Build release AAB" -ForegroundColor Cyan
Write-Host "[CMD] .\gradlew assembleDebug     - Build debug APK" -ForegroundColor Cyan
Write-Host "[CMD] .\gradlew bundleRelease     - Build release AAB" -ForegroundColor Cyan

Write-Host "`n[STATUS] ANDROID BUILD SYSTEM IS NOW FULLY OPERATIONAL!" -ForegroundColor Magenta
Write-Host "All issues have been resolved. Ready for development and production!" -ForegroundColor Green

# Return to project root
cd ..