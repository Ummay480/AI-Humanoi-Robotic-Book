# Android Build Fix - Basic Version

Write-Host "=== ANDROID BUILD FIX ===" -ForegroundColor Green
Write-Host "Starting Android build fix process..." -ForegroundColor Yellow

# Set location to android directory
Set-Location "android"

Write-Host "🔧 Stopping Gradle daemons..." -ForegroundColor Cyan
try {
    .\gradlew.bat --stop
    Write-Host "✅ Gradle daemons stopped" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not stop Gradle daemons: $_" -ForegroundColor Yellow
}

Write-Host "🧹 Cleaning caches..." -ForegroundColor Cyan
# Clean cache locations
$locations = @(".gradle", "build", "app\build")

foreach ($location in $locations) {
    if (Test-Path $location) {
        Remove-Item -Path $location -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Removed $location" -ForegroundColor Green
    }
}

Write-Host "🔧 Setting up Java 21 in gradle.properties..." -ForegroundColor Cyan

# Update gradle.properties to use Java 21
$gradlePropsPath = "gradle.properties"
if (Test-Path $gradlePropsPath) {
    $content = Get-Content $gradlePropsPath

    # Remove any existing java home settings
    $content = $content | Where-Object { $_ -notmatch "^org.gradle.java.home=" }

    # Add Java 21 path
    $java21Path = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
    $content += "org.gradle.java.home=$java21Path"
    $content += "org.gradle.java.installations.auto-detect=false"
    $content += "org.gradle.java.installations.auto-download=false"

    Set-Content $gradlePropsPath $content
    Write-Host "✅ Updated gradle.properties with Java 21 path" -ForegroundColor Green
}

Write-Host "🔧 Updating app/build.gradle for Java 21..." -ForegroundColor Cyan

# Update app/build.gradle to use Java 21
$appBuildGradlePath = "app\build.gradle"
if (Test-Path $appBuildGradlePath) {
    $content = Get-Content $appBuildGradlePath

    # Update or add Java 21 settings
    $foundSourceCompatibility = $false
    $foundTargetCompatibility = $false
    $foundJvmTarget = $false

    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match "sourceCompatibility.*VERSION") {
            $content[$i] = "        sourceCompatibility JavaVersion.VERSION_21"
            $foundSourceCompatibility = $true
        }
        if ($content[$i] -match "targetCompatibility.*VERSION") {
            $content[$i] = "        targetCompatibility JavaVersion.VERSION_21"
            $foundTargetCompatibility = $true
        }
        if ($content[$i] -match "jvmTarget.*=") {
            $content[$i] = "        jvmTarget = '21'"
            $foundJvmTarget = $true
        }
    }

    # If not found, try to add them to appropriate sections
    if (-not $foundSourceCompatibility -or -not $foundTargetCompatibility) {
        for ($i = 0; $i -lt $content.Length; $i++) {
            if ($content[$i] -match "compileOptions\s*\{") {
                if (-not $foundSourceCompatibility) {
                    $content = $content[0..$i] + "        sourceCompatibility JavaVersion.VERSION_21" + $content[($i+1)..($content.Length-1)]
                    $i++
                }
                if (-not $foundTargetCompatibility) {
                    $content = $content[0..$i] + "        targetCompatibility JavaVersion.VERSION_21" + $content[($i+1)..($content.Length-1)]
                    $i++
                }
            }
        }
    }

    if (-not $foundJvmTarget) {
        for ($i = 0; $i -lt $content.Length; $i++) {
            if ($content[$i] -match "kotlinOptions\s*\{") {
                $content = $content[0..$i] + "        jvmTarget = '21'" + $content[($i+1)..($content.Length-1)]
                $i++
            }
        }
    }

    Set-Content $appBuildGradlePath $content
    Write-Host "✅ Updated app/build.gradle for Java 21" -ForegroundColor Green
}

Write-Host "🔧 Verifying settings.gradle repository configuration..." -ForegroundColor Cyan

$settingsGradlePath = "settings.gradle"
if (Test-Path $settingsGradlePath) {
    $content = Get-Content $settingsGradlePath

    # Check if RepositoriesMode.PREFER_SETTINGS is set
    $hasRepoMode = $content -match "RepositoriesMode.PREFER_SETTINGS"

    if (-not $hasRepoMode) {
        # Try to add it to dependencyResolutionManagement block
        for ($i = 0; $i -lt $content.Length; $i++) {
            if ($content[$i] -match "dependencyResolutionManagement\s*\{") {
                $content = $content[0..$i] + "    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)" + $content[($i+1)..($content.Length-1)]
                break
            }
        }
    }

    Set-Content $settingsGradlePath $content
    Write-Host "✅ Verified settings.gradle repository configuration" -ForegroundColor Green
}

Write-Host "🔧 Setting environment variables..." -ForegroundColor Cyan
$env:JAVA_HOME = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
Write-Host "✅ Environment variables set" -ForegroundColor Green

Write-Host "🔧 Attempting build..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

try {
    # Run a basic build
    $result = Start-Process -FilePath ".\gradlew.bat" -ArgumentList "assembleDebug", "--no-daemon" -Wait -PassThru -NoNewWindow
    if ($result.ExitCode -eq 0) {
        Write-Host "✅ BUILD SUCCESSFUL!" -ForegroundColor Green

        # Look for APK file
        $apkFiles = Get-ChildItem -Path "app\build\outputs\apk\debug" -Filter "*.apk" -ErrorAction SilentlyContinue
        if ($apkFiles) {
            foreach ($apk in $apkFiles) {
                $sizeMB = [math]::Round($apk.Length / 1MB, 2)
                Write-Host "📱 APK: $($apk.Name) ($sizeMB MB)" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "❌ Build failed with exit code: $($result.ExitCode)" -ForegroundColor Red
        Write-Host "Check output for details. You may need to run './gradlew assembleDebug --info' manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Build process error: $_" -ForegroundColor Red
}

Write-Host "`n🎉 Android build fix process completed!" -ForegroundColor Green
Write-Host "Check the android directory for any remaining issues." -ForegroundColor Yellow