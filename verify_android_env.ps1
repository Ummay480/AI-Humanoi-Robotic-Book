# verify_android_env.ps1
Write-Host "=== ANDROID BUILD ENVIRONMENT VERIFICATION ===" -ForegroundColor Magenta

# Check Java
Write-Host "`n[INFO] Java Configuration:" -ForegroundColor Cyan
$javaHome = [System.Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')
if ([string]::IsNullOrEmpty($javaHome)) {
    $javaHome = [System.Environment]::GetEnvironmentVariable('JAVA_HOME', 'User')
}
if ([string]::IsNullOrEmpty($javaHome)) {
    $javaHome = $env:JAVA_HOME
}

if ($javaHome -like "*jdk-21*") {
    Write-Host "[SUCCESS] JAVA_HOME correctly set to Java 21: $javaHome" -ForegroundColor Green
    java -version 2>&1 | Select-Object -First 1
} else {
    Write-Host "[ERROR] JAVA_HOME not set correctly: $javaHome" -ForegroundColor Red
}

# Check AndroidX configuration
Write-Host "`n[INFO] AndroidX Configuration:" -ForegroundColor Cyan
if (Test-Path "D:\AIDD\ai-humanoid-app\android\gradle.properties") {
    $gradleProps = Get-Content "D:\AIDD\ai-humanoid-app\android\gradle.properties"
    if ($gradleProps -match "android\.useAndroidX=true") {
        Write-Host "[SUCCESS] AndroidX enabled" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] AndroidX not enabled" -ForegroundColor Red
    }
}

# Check build outputs
Write-Host "`n[INFO] Build Outputs:" -ForegroundColor Cyan
cd "D:\AIDD\ai-humanoid-app\android"

$debugApk = Get-ChildItem "app\build\outputs\apk\debug\*.apk" -ErrorAction SilentlyContinue
$releaseAab = Get-ChildItem "app\build\outputs\bundle\release\*.aab" -ErrorAction SilentlyContinue

if ($debugApk) {
    Write-Host "[SUCCESS] Debug APK available: $($debugApk.Count) file(s)" -ForegroundColor Green
    $debugApk | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   - $($_.Name) ($size MB)"
    }
} else {
    Write-Host "[WARNING] No debug APK found" -ForegroundColor Yellow
}

if ($releaseAab) {
    Write-Host "[SUCCESS] Release AAB available: $($releaseAab.Count) file(s)" -ForegroundColor Green
    $releaseAab | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   - $($_.Name) ($size MB)"
    }
} else {
    Write-Host "[INFO] No release AAB found (requires signing key for release builds)" -ForegroundColor Cyan
}

Write-Host "`n[TARGET] VERIFICATION COMPLETE" -ForegroundColor Cyan