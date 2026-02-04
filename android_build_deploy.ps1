# Android Build & Deploy Assistant Script
# Created by Claude for ai-humanoid-app project
# Features: Pre-checks, cleaning, building, deploying, verification

param(
    [switch]$SkipPreChecks,
    [switch]$CleanOnly,
    [string]$DeviceId,
    [switch]$Verbose
)

# ANSI Color Codes for PowerShell
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

# Counter for steps
$stepCount = 0
$totalSteps = 10

function Write-ColoredOutput {
    param([string]$color, [string]$message)
    Write-Host "$color$message$Reset"
}

function Start-Step {
    param([string]$description)
    $script:stepCount++
    Write-ColoredOutput $Blue "Step $stepCount/$totalSteps: $description..."
}

function Measure-Time {
    param([ScriptBlock]$Command)
    $start = Get-Date
    try {
        $result = & $Command
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        return $result, $duration
    }
    catch {
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        throw $_
    }
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "    ANDROID BUILD & DEPLOY ASSISTANT" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# PART 1: PRE-CHECKS
Start-Step "Checking prerequisites"

# Check current directory
$currentPath = Get-Location
Write-ColoredOutput $Yellow "Current directory: $currentPath"

if (-not (Test-Path ".\android")) {
    Write-ColoredOutput $Red "❌ Android folder not found in current directory!"
    Write-Host "Please navigate to the project root containing the android folder."
    exit 1
} else {
    Write-ColoredOutput $Green "✅ Android folder found"
}

# Check Java version
Start-Step "Checking Java version"
try {
    $javaVersion = java -version 2>&1
    $javaVersionStr = $javaVersion -match "version"
    if ($javaVersionStr) {
        $versionMatch = [regex]::Match($javaVersionStr[0], '"(\d+(?:\.\d+)*)"')
        if ($versionMatch.Success) {
            $versionNum = [int][string]$versionMatch.Groups[1].Value.Split('.')[0]
            if ($versionNum -ge 17) {
                Write-ColoredOutput $Green "✅ Java $versionNum found (meets requirement >= 17)"
            } else {
                Write-ColoredOutput $Red "❌ Java version $versionNum is too low. Need Java 17 or higher."
                exit 1
            }
        } else {
            Write-ColoredOutput $Yellow "⚠️ Could not determine Java version"
        }
    } else {
        Write-ColoredOutput $Red "❌ Java not found. Please install Java 17 or higher."
        exit 1
    }
} catch {
    Write-ColoredOutput $Red "❌ Java not found. Please install Java 17 or higher."
    exit 1
}

# Check Gradle version
Start-Step "Checking Gradle version"
try {
    $gradleVersion = gradle --version 2>$null
    if ($gradleVersion) {
        $versionLine = $gradleVersion | Select-String "Gradle"
        if ($versionLine) {
            Write-ColoredOutput $Green "✅ Gradle found: $($versionLine.Line.Trim())"
        } else {
            Write-ColoredOutput $Yellow "⚠️ Could not determine Gradle version"
        }
    } else {
        Write-ColoredOutput $Red "❌ Gradle not found"
        exit 1
    }
} catch {
    Write-ColoredOutput $Red "❌ Gradle not found"
    exit 1
}

# Check ADB devices
Start-Step "Checking ADB devices"
try {
    $adbDevices = adb devices 2>$null
    $deviceLines = $adbDevices | Where-Object { $_ -match "device$" -and $_ -notmatch "List of devices" }

    if ($deviceLines.Count -eq 0) {
        Write-ColoredOutput $Red "❌ No ADB devices connected!"
        Write-Host "Please connect your Android device via USB and enable USB debugging."
        Write-Host "Instructions:"
        Write-Host "  1. Enable Developer Options on your Android device"
        Write-Host "  2. Enable USB Debugging in Developer Options"
        Write-Host "  3. Connect device via USB"
        Write-Host "  4. Tap 'Allow' on the USB debugging authorization popup"
        exit 1
    } else {
        Write-ColoredOutput $Green "✅ ADB devices connected: $($deviceLines.Count)"
        foreach ($line in $deviceLines) {
            Write-Host "   $line"
        }
    }
} catch {
    Write-ColoredOutput $Red "❌ ADB not found or not in PATH"
    Write-Host "Please ensure Android SDK Platform Tools are installed and in your PATH."
    exit 1
}

# Check required files
Start-Step "Checking project files"
$requiredFiles = @("variables.gradle", "capacitor.settings.gradle", "build.gradle")
$optionalFiles = @("google-services.json")

foreach ($file in $requiredFiles) {
    $filePath = ".\android\$file"
    if (Test-Path $filePath) {
        Write-ColoredOutput $Green "✅ $file found"
    } else {
        Write-ColoredOutput $Red "❌ $file not found in android folder"
        exit 1
    }
}

foreach ($file in $optionalFiles) {
    $filePath = ".\android\$file"
    if (Test-Path $filePath) {
        Write-ColoredOutput $Green "✅ $file found"
    } else {
        Write-ColoredOutput $Yellow "⚠️ $file not found (optional)"
    }
}

# Navigate to android directory
Push-Location ".\android"

# PART 2: CLEAN AND FIX
if ($CleanOnly) {
    Start-Step "Performing clean only"
    Write-ColoredOutput $Blue "🧹 Cleaning build directories..."

    $cleanResult, $cleanDuration = Measure-Time {
        .\gradlew clean --no-daemon
    }

    if ($LASTEXITCODE -eq 0) {
        Write-ColoredOutput $Green "✅ Clean completed successfully in ${cleanDuration}s"
    } else {
        Write-ColoredOutput $Red "❌ Clean failed with exit code $LASTEXITCODE"
        Pop-Location
        exit $LASTEXITCODE
    }

    Pop-Location
    Write-ColoredOutput $Green "🎉 Clean operation completed!"
    exit 0
}

Start-Step "Cleaning project"
Write-ColoredOutput $Blue "🧹 Stopping Gradle daemons and removing old build files..."

# Stop Gradle daemons
Stop-Process -Name "java" -ErrorAction SilentlyContinue | Out-Null
.\gradlew --stop

# Clean build directories
Remove-Item -Recurse -Force ".\app\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\.gradle" -ErrorAction SilentlyContinue

Write-ColoredOutput $Green "✅ Project cleaned successfully"

# Check and fix variables.gradle if needed
Start-Step "Verifying variables.gradle configuration"
$variablesGradlePath = ".\variables.gradle"
$needsUpdate = $false

if (Test-Path $variablesGradlePath) {
    $content = Get-Content $variablesGradlePath -Raw
    if ($content -notmatch "compileSdkVersion") {
        Write-ColoredOutput $Yellow "⚠️ variables.gradle missing required configurations, updating..."
        $needsUpdate = $true
    } else {
        Write-ColoredOutput $Green "✅ variables.gradle has required configurations"
    }
} else {
    Write-ColoredOutput $Yellow "⚠️ variables.gradle not found, creating with defaults..."
    $needsUpdate = $true
}

if ($needsUpdate) {
    $defaultVariables = @"
ext {
    compileSdkVersion = 35
    minSdkVersion = 24
    targetSdkVersion = 35
    androidxAppCompatVersion = '1.6.1'
    androidxCoordinatorLayoutVersion = '1.2.0'
    coreSplashScreenVersion = '1.0.1'
    junitVersion = '4.13.2'
    androidxJunitVersion = '1.1.5'
    androidxEspressoCoreVersion = '3.5.1'
}
"@
    Set-Content -Path $variablesGradlePath -Value $defaultVariables
    Write-ColoredOutput $Green "✅ variables.gradle created with default configurations"
}

# PART 3: BUILD
Start-Step "Building Android app"
Write-ColoredOutput $Blue "🏗️ Starting build process... This may take 5-10 minutes."

# Capture build output to file
$logFile = "..\build_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

$buildResult, $buildDuration = Measure-Time {
    .\gradlew assembleDebug --info 2>&1 | Tee-Object -FilePath $logFile
}

if ($LASTEXITCODE -eq 0) {
    Write-ColoredOutput $Green "✅ BUILD SUCCESSFUL in ${buildDuration}s!"

    # Find the APK file
    $apkPath = Get-ChildItem -Path ".\app\build\outputs\apk\debug" -Filter "*.apk" -Recurse | Select-Object -First 1
    if ($apkPath) {
        $apkSizeMB = [math]::Round($apkPath.Length / 1MB, 2)
        Write-ColoredOutput $Green "📱 APK created: $($apkPath.Name) ($($apkSizeMB) MB)"
        Write-Host "   Location: $($apkPath.FullName)"
    } else {
        Write-ColoredOutput $Red "❌ APK file not found in expected location"
        Pop-Location
        exit 1
    }
} else {
    Write-ColoredOutput $Red "❌ BUILD FAILED with exit code $LASTEXITCODE"
    Write-Host "Build log saved to: $logFile"
    Write-Host "Troubleshooting tips:"
    Write-Host "  1. Check the log file for specific error messages"
    Write-Host "  2. Ensure all Android SDK components are installed"
    Write-Host "  3. Try running 'npx cap sync android' to sync Capacitor plugins"
    Write-Host "  4. Verify your variables.gradle configuration"

    Pop-Location
    exit $LASTEXITCODE
}

# PART 4: DEPLOY TO DEVICE
Start-Step "Listing connected devices"
$adbDevices = adb devices
$deviceLines = $adbDevices | Where-Object { $_ -match "device$" -and $_ -notmatch "List of devices" }

if ($deviceLines.Count -eq 0) {
    Write-ColoredOutput $Red "❌ No devices connected!"
    Pop-Location
    exit 1
}

Write-Host "Connected devices:"
for ($i = 0; $i -lt $deviceLines.Count; $i++) {
    $deviceInfo = $deviceLines[$i].Split("`t")[0]
    Write-Host "  $($i + 1). $deviceInfo"
}

# Choose device
$selectedDevice = ""
if ($DeviceId) {
    $selectedDevice = $DeviceId
    Write-Host "Using specified device: $selectedDevice"
} else {
    if ($deviceLines.Count -eq 1) {
        $selectedDevice = $deviceLines[0].Split("`t")[0]
        Write-Host "Auto-selecting only connected device: $selectedDevice"
    } else {
        do {
            $choice = Read-Host "Which device to deploy to? (1-$($deviceLines.Count))"
            $choiceNum = [int]$choice - 1
            if ($choiceNum -ge 0 -and $choiceNum -lt $deviceLines.Count) {
                $selectedDevice = $deviceLines[$choiceNum].Split("`t")[0]
                break
            } else {
                Write-ColoredOutput $Red "❌ Invalid selection. Please enter a number between 1 and $($deviceLines.Count)."
            }
        } while ($true)
    }
}

# Set ADB to target selected device
$env:ANDROID_SERIAL = $selectedDevice

Start-Step "Installing on device $selectedDevice"
Write-ColoredOutput $Blue "📤 Installing app to device..."

# Get APK path again
$apkPath = Get-ChildItem -Path ".\app\build\outputs\apk\debug" -Filter "*.apk" -Recurse | Select-Object -First 1

if (-not $apkPath) {
    Write-ColoredOutput $Red "❌ APK file not found!"
    Pop-Location
    exit 1
}

$installResult, $installDuration = Measure-Time {
    adb install -r $apkPath.FullName 2>&1
}

if ($LASTEXITCODE -eq 0 -or $installResult -match "Success") {
    Write-ColoredOutput $Green "✅ App installed successfully in ${installDuration}s!"
} else {
    Write-ColoredOutput $Red "❌ Installation failed: $($installResult | Out-String)"

    # Try alternative installation method
    Write-Host "Trying alternative installation method..."
    $altInstallResult = adb install $apkPath.FullName 2>&1

    if ($LASTEXITCODE -eq 0 -or $altInstallResult -match "Success") {
        Write-ColoredOutput $Green "✅ App installed successfully with alternative method!"
    } else {
        Write-ColoredOutput $Red "❌ Alternative installation also failed: $($altInstallResult | Out-String)"
        Pop-Location
        exit $LASTEXITCODE
    }
}

# Get package name from app/build.gradle
$buildGradlePath = ".\app\build.gradle"
if (Test-Path $buildGradlePath) {
    $buildGradleContent = Get-Content $buildGradlePath -Raw
    $packageMatch = [regex]::Match($buildGradleContent, 'applicationId\s+"([^"]+)"')
    if ($packageMatch.Success) {
        $packageName = $packageMatch.Groups[1].Value
    } else {
        # Try to find namespace instead
        $namespaceMatch = [regex]::Match($buildGradleContent, 'namespace\s+"([^"]+)"')
        if ($namespaceMatch.Success) {
            $packageName = $namespaceMatch.Groups[1].Value
        } else {
            Write-ColoredOutput $Yellow "⚠️ Could not extract package name from build.gradle"
            $packageName = "com.kulsoom.aihumanoidbook"  # Default fallback
        }
    }
} else {
    Write-ColoredOutput $Yellow "⚠️ Could not find app/build.gradle, using default package name"
    $packageName = "com.kulsoom.aihumanoidbook"  # Default fallback
}

Start-Step "Launching app on device"
Write-ColoredOutput $Blue "🚀 Launching app on device..."

# Find launcher activity
$launcherActivity = adb shell cmd package resolve-activity --brief $packageName | Select-String $packageName
if ($launcherActivity) {
    $launchCommand = "adb shell am start -n $($launcherActivity.Line.Trim())"
    Invoke-Expression $launchCommand | Out-Null
    Write-ColoredOutput $Green "✅ App launched successfully!"
} else {
    Write-ColoredOutput $Yellow "⚠️ Could not determine launcher activity automatically"
    Write-Host "Attempting to launch with default launcher..."

    # Try to launch with package name only
    $launchAttempt = adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-ColoredOutput $Green "✅ App launched successfully!"
    } else {
        Write-ColoredOutput $Yellow "⚠️ Could not launch app automatically. Please open manually from device launcher."
    }
}

# PART 5: VERIFICATION
Start-Step "Verifying installation"
Write-ColoredOutput $Blue "🔍 Verifying app installation..."

# Check if app is installed
$appInstalled = adb shell pm list packages | Select-String $packageName
if ($appInstalled) {
    Write-ColoredOutput $Green "✅ App verified as installed on device"
} else {
    Write-ColoredOutput $Yellow "⚠️ Could not verify app installation"
}

Pop-Location

# FINAL SUCCESS MESSAGE
Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "         🎉 SUCCESS! 🎉" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host "Your app is now running on device: $selectedDevice" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check your device for the app icon" -ForegroundColor White
Write-Host "2. Look for '$packageName' in your app drawer" -ForegroundColor White
Write-Host "3. If issues occur, try force-stopping and restarting the app" -ForegroundColor White
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "• If app crashes on startup, check Android logs with: adb logcat" -ForegroundColor White
Write-Host "• To rebuild, run: .\android_build_deploy.ps1 -CleanOnly, then run again" -ForegroundColor White
Write-Host "• To deploy to different device: .\android_build_deploy.ps1 -DeviceId 'device_serial'" -ForegroundColor White
Write-Host ""
Write-Host "Build log saved to: $logFile" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Green