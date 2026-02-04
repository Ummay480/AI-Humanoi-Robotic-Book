# quick_build.ps1
param([string]$BuildType = "assembleDebug")

Write-Host "[RUNNING] Quick Android Build: $BuildType" -ForegroundColor Cyan
cd "D:\AIDD\ai-humanoid-app\android"

# Set Java for this session
$env:JAVA_HOME = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# Build
.\gradlew clean $BuildType --no-daemon --stacktrace

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Build successful!" -ForegroundColor Green

    if ($BuildType -eq "assembleDebug") {
        $apk = Get-ChildItem "app\build\outputs\apk\debug\*.apk" | Select-Object -First 1
        if ($apk) {
            $size = [math]::Round($apk.Length / 1MB, 2)
            Write-Host "[APK] $($apk.Name) ($size MB)" -ForegroundColor Green
        }
    } elseif ($BuildType -eq "bundleRelease") {
        $aab = Get-ChildItem "app\build\outputs\bundle\release\*.aab" | Select-Object -First 1
        if ($aab) {
            $size = [math]::Round($aab.Length / 1MB, 2)
            Write-Host "[AAB] $($aab.Name) ($size MB)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
}