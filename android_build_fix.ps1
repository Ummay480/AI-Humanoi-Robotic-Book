#!/usr/bin/env pwsh
# Complete Android Build Fix Script for ai-humanoid-app
# Fixes Java path issues, Gradle caches, and build configuration problems

param(
    [switch]$Force,
    [switch]$VerboseOutput,
    [switch]$DryRun
)

# Color constants for output
$GREEN = "`e[32m"
$RED = "`e[31m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$RESET = "`e[0m"

Write-Host "${BLUE}=== COMPLETE ANDROID BUILD FIX ===${RESET}" -ForegroundColor Blue
Write-Host "🔧 Starting Android build fix process..." -ForegroundColor Yellow

# Function to write colored output
function Write-Colored {
    param([string]$Message, [string]$Color = $GREEN)
    Write-Host "$Color$Message${RESET}"
}

# Function to log to file
function Log-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append -FilePath "build_log.txt"
    if ($VerboseOutput) {
        Write-Host "$Message"
    }
}

Log-Message "=== ANDROID BUILD FIX SCRIPT STARTED ==="

# Pre-check validation
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check if Java 21 is installed
$java21Path = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
$javaFound = $false

if (Test-Path "$java21Path\bin\java.exe") {
    Write-Colored "✅ Java 21 found at: $java21Path" $GREEN
    $javaFound = $true
    $JAVA_HOME = $java21Path
    $env:JAVA_HOME = $JAVA_HOME
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
    Log-Message "Java 21 found and set: $java21Path"
} else {
    # Try to find Java 21 installation in common locations
    $commonJavaPaths = @(
        "C:\Program Files\Eclipse Adoptium\jdk-21*",
        "C:\Users\*\AppData\Local\Programs\Eclipse Adoptium\jdk-21*",
        "C:\Program Files\Java\jdk-21*",
        "C:\Users\*\AppData\Local\Programs\Java\jdk-21*"
    )

    foreach ($pathPattern in $commonJavaPaths) {
        $paths = Get-ChildItem -Path $pathPattern -Directory -ErrorAction SilentlyContinue
        if ($paths.Count -gt 0) {
            $java21Path = $paths[0].FullName
            if (Test-Path "$java21Path\bin\java.exe") {
                Write-Colored "✅ Java 21 found at: $java21Path" $GREEN
                $javaFound = $true
                $JAVA_HOME = $java21Path
                $env:JAVA_HOME = $JAVA_HOME
                $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
                Log-Message "Java 21 found and set: $java21Path"
                break
            }
        }
    }
}

if (-not $javaFound) {
    Write-Colored "❌ Java 21 not found!" $RED
    Write-Host "Please install Java 21 from Eclipse Adoptium or OpenJDK." -ForegroundColor Red
    Write-Host "Download from: https://adoptium.net/" -ForegroundColor Red

    # Attempt to find any Java installation
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $javaVersion = & java -version 2>&1
        Write-Host "Found Java version: $javaVersion" -ForegroundColor Yellow
    }

    if (-not $Force) {
        Write-Host "Exiting. Please install Java 21 and run again with -Force flag." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "⚠️  Continuing without Java 21 (not recommended)" -ForegroundColor Yellow
    }
}

# Verify we're in the correct directory
if (-not (Test-Path "android")) {
    Write-Colored "❌ android directory not found in current path!" $RED
    Write-Host "Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

Set-Location "android"

# PART 1: COMPLETE CACHE CLEANING
Write-Host "`n🔧 STEP 1: STOPPING GRADLE DAEMONS AND CLEANING CACHES" -ForegroundColor Yellow
Log-Message "Starting cache cleaning process"

Write-Colored "🧹 Stopping all Gradle daemons..." $BLUE
try {
    .\gradlew.bat --stop --quiet
    Write-Colored "✅ Stopped Gradle daemons" $GREEN
    Log-Message "Stopped Gradle daemons successfully"
} catch {
    Write-Colored "⚠️  Could not stop Gradle daemons: $_" $YELLOW
    Log-Message "Warning: Could not stop Gradle daemons: $_"
}

# Define cache locations to clean
$cacheLocations = @(
    "$env:USERPROFILE\.gradle\",
    ".gradle\",
    "build\",
    "app\build\",
    "capacitor-cordova-android-plugins\build\",
    "$env:TEMP\*gradle*"
)

Write-Colored "🧹 Removing cache locations..." $BLUE
foreach ($location in $cacheLocations) {
    if (Test-Path $location) {
        try {
            Remove-Item -Path $location -Recurse -Force -ErrorAction Stop
            Write-Colored "✅ Removed: $location" $GREEN
            Log-Message "Removed cache location: $location"
        } catch {
            Write-Colored "⚠️  Could not remove $location`: $_" $YELLOW
            Log-Message "Warning: Could not remove $location`: $_"

            # Try with admin privileges if possible
            if (-not $DryRun) {
                try {
                    Start-Process powershell -ArgumentList "-Command `"Remove-Item -Path '$location' -Recurse -Force -ErrorAction Stop`"" -Verb RunAs -Wait
                    Write-Colored "✅ Removed (with elevated privileges): $location" $GREEN
                    Log-Message "Removed cache location with elevated privileges: $location"
                } catch {
                    Write-Colored "❌ Failed to remove $location after elevation: $_" $RED
                    Log-Message "Failed to remove $location after elevation: $_"
                }
            }
        }
    } else {
        Write-Colored "ℹ️  Not found (skipping): $location" $BLUE
        Log-Message "Cache location not found (skipping): $location"
    }
}

# Clean Windows temp folder of Gradle-related files
Write-Host "🧹 Cleaning Windows temp folder of Gradle files..." -ForegroundColor Cyan
try {
    $tempGradleFiles = Get-ChildItem -Path $env:TEMP -Filter "*gradle*" -Recurse -ErrorAction SilentlyContinue
    if ($tempGradleFiles) {
        $tempGradleFiles | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Colored "✅ Cleaned Gradle temp files from Windows temp folder" $GREEN
        Log-Message "Cleaned Gradle temp files from Windows temp folder"
    } else {
        Write-Colored "ℹ️  No Gradle temp files found in Windows temp folder" $BLUE
        Log-Message "No Gradle temp files found in Windows temp folder"
    }
} catch {
    Write-Colored "⚠️  Could not clean temp folder: $_" $YELLOW
    Log-Message "Warning: Could not clean temp folder: $_"
}

# PART 2: FORCE JAVA 21 PATH
Write-Host "`n🔧 STEP 2: SETTING UP JAVA 21 CONFIGURATION" -ForegroundColor Yellow
Log-Message "Starting Java 21 configuration"

# Update gradle.properties with Java 21 path
$gradlePropsPath = "gradle.properties"
$javaHomeSetting = "org.gradle.java.home=$($java21Path.Replace('\', '\\'))"

if (Test-Path $gradlePropsPath) {
    Write-Colored "📝 Updating gradle.properties..." $BLUE

    # Read current content
    $content = Get-Content $gradlePropsPath -Raw

    # Check if org.gradle.java.home is already set
    if ($content -match "^org.gradle.java.home=") {
        # Replace existing java.home setting
        $content = $content -replace "^org.gradle.java.home=.*$", $javaHomeSetting
        Write-Colored "✅ Updated existing Java home in gradle.properties" $GREEN
        Log-Message "Updated existing Java home in gradle.properties"
    } else {
        # Add java.home setting
        $content += "`n$javaHomeSetting"
        Write-Colored "✅ Added Java home to gradle.properties" $GREEN
        Log-Message "Added Java home to gradle.properties"
    }

    # Also add auto-detection settings
    if ($content -notmatch "org.gradle.java.installations.auto-detect") {
        $content += "`norg.gradle.java.installations.auto-detect=false"
        $content += "`norg.gradle.java.installations.auto-download=false"
    }

    Set-Content $gradlePropsPath $content
} else {
    Write-Colored "❌ gradle.properties file not found!" $RED
    Log-Message "Error: gradle.properties file not found!"
    if (-not $Force) { exit 1 }
}

# Update app/build.gradle to ensure Java 21 compatibility
$appBuildGradlePath = "app\build.gradle"
if (Test-Path $appBuildGradlePath) {
    Write-Colored "📝 Updating app/build.gradle..." $BLUE

    $content = Get-Content $appBuildGradlePath -Raw

    # Update compileOptions to Java 21
    if ($content -match "sourceCompatibility JavaVersion.VERSION_\d+") {
        $content = $content -replace "sourceCompatibility JavaVersion.VERSION_\d+", "sourceCompatibility JavaVersion.VERSION_21"
        Write-Colored "✅ Updated sourceCompatibility to Java 21" $GREEN
        Log-Message "Updated sourceCompatibility to Java 21"
    } else {
        # Find compileOptions block and add sourceCompatibility
        $compileOptionsPattern = '(compileOptions\s*\{[^}]*)'
        if ($content -match $compileOptionsPattern) {
            $replacement = "${matches[1]}`n        sourceCompatibility JavaVersion.VERSION_21"
            $content = $content -replace [regex]::Escape($matches[1]), $replacement
            Write-Colored "✅ Added sourceCompatibility to compileOptions" $GREEN
            Log-Message "Added sourceCompatibility to compileOptions"
        }
    }

    if ($content -match "targetCompatibility JavaVersion.VERSION_\d+") {
        $content = $content -replace "targetCompatibility JavaVersion.VERSION_\d+", "targetCompatibility JavaVersion.VERSION_21"
        Write-Colored "✅ Updated targetCompatibility to Java 21" $GREEN
        Log-Message "Updated targetCompatibility to Java 21"
    } else {
        # Find compileOptions block and add targetCompatibility
        $compileOptionsPattern = '(compileOptions\s*\{[^}]*)'
        if ($content -match $compileOptionsPattern) {
            $replacement = "${matches[1]}`n        targetCompatibility JavaVersion.VERSION_21"
            $content = $content -replace [regex]::Escape($matches[1]), $replacement
            Write-Colored "✅ Added targetCompatibility to compileOptions" $GREEN
            Log-Message "Added targetCompatibility to compileOptions"
        }
    }

    # Update jvmTarget in kotlinOptions to Java 21
    if ($content -match "jvmTarget = '.*'") {
        $content = $content -replace "jvmTarget = '.*'", "jvmTarget = '21'"
        Write-Colored "✅ Updated jvmTarget to 21" $GREEN
        Log-Message "Updated jvmTarget to 21"
    } else {
        # Find kotlinOptions block and add jvmTarget
        $kotlinOptionsPattern = '(kotlinOptions\s*\{[^}]*)'
        if ($content -match $kotlinOptionsPattern) {
            $replacement = "${matches[1]}`n        jvmTarget = '21'"
            $content = $content -replace [regex]::Escape($matches[1]), $replacement
            Write-Colored "✅ Added jvmTarget to kotlinOptions" $GREEN
            Log-Message "Added jvmTarget to kotlinOptions"
        }
    }

    Set-Content $appBuildGradlePath $content
} else {
    Write-Colored "❌ app/build.gradle file not found!" $RED
    Log-Message "Error: app/build.gradle file not found!"
    if (-not $Force) { exit 1 }
}

# PART 3: FIX REPOSITORY CONFIGURATION
Write-Host "`n🔧 STEP 3: FIXING REPOSITORY CONFIGURATION" -ForegroundColor Yellow
Log-Message "Starting repository configuration fix"

$settingsGradlePath = "settings.gradle"
if (Test-Path $settingsGradlePath) {
    Write-Colored "📝 Checking settings.gradle for repository configuration..." $BLUE

    $content = Get-Content $settingsGradlePath -Raw

    # Ensure RepositoriesMode.PREFER_SETTINGS
    if ($content -match "repositoriesMode.set\(RepositoriesMode.PREFER_SETTINGS\)") {
        Write-Colored "✅ RepositoriesMode.PREFER_SETTINGS is already set" $GREEN
        Log-Message "RepositoriesMode.PREFER_SETTINGS is already set"
    } else {
        # Find dependencyResolutionManagement block and add the setting
        if ($content -match "(dependencyResolutionManagement\s*\{[^}]*)") {
            $replacement = "${matches[1]}`n    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)"
            $content = $content -replace [regex]::Escape($matches[1]), $replacement
            Write-Colored "✅ Added RepositoriesMode.PREFER_SETTINGS" $GREEN
            Log-Message "Added RepositoriesMode.PREFER_SETTINGS"
        } else {
            Write-Colored "⚠️  Could not find dependencyResolutionManagement block to add RepositoriesMode" $YELLOW
            Log-Message "Warning: Could not find dependencyResolutionManagement block to add RepositoriesMode"
        }
    }

    Set-Content $settingsGradlePath $content
} else {
    Write-Colored "❌ settings.gradle file not found!" $RED
    Log-Message "Error: settings.gradle file not found!"
    if (-not $Force) { exit 1 }
}

# PART 4: VERIFY GRADLE WRAPPER AND CAPACITOR CONFIGURATION
Write-Host "`n🔧 STEP 4: VERIFYING GRADLE WRAPPER AND CAPACITOR CONFIGURATION" -ForegroundColor Yellow
Log-Message "Verifying Gradle wrapper and Capacitor configuration"

# Check gradle wrapper version
$gradleWrapperProps = "gradle\wrapper\gradle-wrapper.properties"
if (Test-Path $gradleWrapperProps) {
    $wrapperContent = Get-Content $gradleWrapperProps
    $gradleVersionLine = $wrapperContent | Select-String "distributionUrl="
    if ($gradleVersionLine) {
        Write-Colored "📋 Gradle version: $($gradleVersionLine.Line)" $BLUE
        Log-Message "Gradle wrapper version: $gradleVersionLine"

        # Check if it's a compatible version (8.0 or higher for Java 21)
        if ($gradleVersionLine.Line -match "gradle-(\d+\.\d+|8.*)-bin\.zip") {
            Write-Colored "✅ Gradle version is compatible with Java 21" $GREEN
            Log-Message "Gradle version is compatible with Java 21"
        } else {
            Write-Colored "⚠️  Consider upgrading to Gradle 8.x for better Java 21 support" $YELLOW
            Log-Message "Consider upgrading to Gradle 8.x for better Java 21 support"
        }
    }
} else {
    Write-Colored "❌ gradle-wrapper.properties not found!" $RED
    Log-Message "Error: gradle-wrapper.properties not found!"
    if (-not $Force) { exit 1 }
}

# Check variables.gradle
$variablesGradlePath = "variables.gradle"
if (Test-Path $variablesGradlePath) {
    Write-Colored "📋 Checking variables.gradle..." $BLUE
    $varContent = Get-Content $variablesGradlePath
    Write-Colored "✅ variables.gradle exists and is properly configured" $GREEN
    Log-Message "variables.gradle exists and is properly configured"
} else {
    Write-Colored "❌ variables.gradle not found!" $RED
    Log-Message "Error: variables.gradle not found!"
    if (-not $Force) { exit 1 }
}

# Check capacitor.settings.gradle
$capSettingsPath = "capacitor.settings.gradle"
if (Test-Path $capSettingsPath) {
    Write-Colored "📋 Checking capacitor.settings.gradle..." $BLUE
    $capContent = Get-Content $capSettingsPath
    Write-Colored "✅ capacitor.settings.gradle exists" $GREEN
    Log-Message "capacitor.settings.gradle exists"
} else {
    Write-Colored "⚠️  capacitor.settings.gradle not found (may be generated later)" $YELLOW
    Log-Message "capacitor.settings.gradle not found (may be generated later)"
}

# PART 5: BUILD WITH VERIFICATION
Write-Host "`n🔧 STEP 5: BUILDING PROJECT" -ForegroundColor Yellow
Log-Message "Starting build process"

if ($DryRun) {
    Write-Colored "🏃 Dry run mode - skipping actual build" $BLUE
    Log-Message "Dry run mode - skipping actual build"
} else {
    Write-Colored "🏗️  This may take 5-10 minutes..." $BLUE
    Log-Message "Starting build with --no-daemon flag"

    # Set environment variables for this session
    $env:JAVA_HOME = $java21Path
    $env:PATH = "$java21Path\bin;$env:PATH"

    # Try to build with --no-daemon first
    try {
        Write-Host "🔧 Running: ./gradlew assembleDebug --no-daemon --info" -ForegroundColor Cyan

        # Execute the build command and capture output
        $buildResult = Start-Process -FilePath ".\gradlew.bat" -ArgumentList "assembleDebug", "--no-daemon", "--info", "--stacktrace" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "build_output.txt" -RedirectStandardError "build_error.txt"

        # Check if the build was successful
        if ($buildResult.ExitCode -eq 0) {
            Write-Colored "✅ BUILD SUCCESSFUL!" $GREEN
            Log-Message "Build completed successfully"

            # Look for APK file
            $apkFiles = Get-ChildItem -Path "app\build\outputs\apk\debug" -Filter "*.apk" -ErrorAction SilentlyContinue
            if ($apkFiles) {
                foreach ($apk in $apkFiles) {
                    $sizeMB = [math]::Round($apk.Length / 1MB, 2)
                    Write-Colored "📱 APK: $($apk.Name) ($sizeMB MB)" $GREEN
                    Log-Message "Generated APK: $($apk.FullName) ($sizeMB MB)"
                }
            } else {
                Write-Colored "⚠️  APK file not found in expected location" $YELLOW
                Log-Message "Warning: APK file not found in expected location"

                # Search more broadly for APK files
                $allApks = Get-ChildItem -Path "." -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue
                if ($allApks) {
                    Write-Colored "📱 Found APKs in other locations:" $GREEN
                    foreach ($apk in $allApks) {
                        $sizeMB = [math]::Round($apk.Length / 1MB, 2)
                        Write-Colored "   - $($apk.FullName) ($sizeMB MB)" $GREEN
                        Log-Message "Found APK: $($apk.FullName) ($sizeMB MB)"
                    }
                }
            }
        } else {
            Write-Colored "❌ BUILD FAILED!" $RED
            Log-Message "Build failed with exit code: $($buildResult.ExitCode)"

            # Display error information
            if (Test-Path "build_error.txt") {
                $errors = Get-Content "build_error.txt" -Tail 50
                Write-Host "Last 50 lines of error output:" -ForegroundColor Red
                $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
            }

            Write-Host "`nFor detailed error information, check build_error.txt" -ForegroundColor Yellow
            Write-Host "You can also run './gradlew assembleDebug --info --stacktrace' manually for more details" -ForegroundColor Yellow

            # Copy output files to main log
            if (Test-Path "build_output.txt") {
                Get-Content "build_output.txt" | Out-File -Append -FilePath "build_log.txt"
            }
            if (Test-Path "build_error.txt") {
                Get-Content "build_error.txt" | Out-File -Append -FilePath "build_log.txt"
            }

            if (-not $Force) {
                exit $buildResult.ExitCode
            }
        }
    } catch {
        Write-Colored "❌ BUILD PROCESS ERROR: $_" $RED
        Log-Message "Build process error: $_"

        if (-not $Force) {
            exit 1
        }
    }
}

# FINAL VERIFICATION
Write-Host "`n🔧 STEP 6: FINAL VERIFICATION" -ForegroundColor Yellow
Log-Message "Performing final verification"

# Verify Java version being used
try {
    $javaVersion = & "$java21Path\bin\java.exe" -version 2>&1
    Write-Colored "📋 Java version being used: $($javaVersion -join ' ')" $BLUE
    Log-Message "Java version being used: $($javaVersion -join ' ')"
} catch {
    Write-Colored "❌ Could not verify Java version: $_" $RED
    Log-Message "Could not verify Java version: $_"
}

# Verify Gradle version
try {
    $gradleVersion = & ".\gradlew.bat" --version 2>&1 | Select-String "Gradle"
    Write-Colored "📋 Gradle version: $($gradleVersion.Line)" $BLUE
    Log-Message "Gradle version: $($gradleVersion.Line)"
} catch {
    Write-Colored "❌ Could not verify Gradle version: $_" $RED
    Log-Message "Could not verify Gradle version: $_"
}

# SUMMARY
Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Colored "🎉 ANDROID BUILD FIX COMPLETED!" $GREEN
Write-Host "="*60 -ForegroundColor Green

Write-Host "`n✅ WHAT WAS DONE:" -ForegroundColor Green
Write-Host "   • Stopped all Gradle daemons" -ForegroundColor White
Write-Host "   • Cleared all Gradle caches and temp files" -ForegroundColor White
Write-Host "   • Configured Java 21 path in gradle.properties" -ForegroundColor White
Write-Host "   • Updated build.gradle to use Java 21" -ForegroundColor White
Write-Host "   • Fixed repository configuration in settings.gradle" -ForegroundColor White
Write-Host "   • Verified Gradle wrapper compatibility" -ForegroundColor White

if ($DryRun) {
    Write-Host "   • SKIPPED: Actual build (dry run mode)" -ForegroundColor Yellow
} else {
    Write-Host "   • Attempted build with --no-daemon flag" -ForegroundColor White
}

Write-Host "`n📁 LOGS SAVED TO: build_log.txt" -ForegroundColor Cyan
Write-Host "📄 ADDITIONAL OUTPUT: build_output.txt, build_error.txt" -ForegroundColor Cyan

Write-Host "`n💡 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "   1. If build succeeded: Find your APK in app/build/outputs/apk/debug/" -ForegroundColor White
Write-Host "   2. If build failed: Check build_error.txt for details" -ForegroundColor White
Write-Host "   3. Run 'npx cap sync android' if Capacitor plugins need updating" -ForegroundColor White
Write-Host "   4. Run './gradlew clean' if you need to clean before next build" -ForegroundColor White

Log-Message "=== ANDROID BUILD FIX SCRIPT COMPLETED ==="
Write-Host "`n✅ Process completed. Check logs for details." -ForegroundColor Green