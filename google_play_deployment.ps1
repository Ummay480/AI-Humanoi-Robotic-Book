# GOOGLE PLAY DEPLOYMENT GUIDE
Write-Host "=== GOOGLE PLAY DEPLOYMENT CHECKLIST ===" -ForegroundColor Magenta

# 1. AAB File
Write-Host "`n1️⃣ AAB FILE:" -ForegroundColor Cyan
$aab = Get-ChildItem "D:\AIDD\ai-humanoid-app\android\app\build\outputs\bundle\release\*.aab" -ErrorAction SilentlyContinue
if ($aab) {
    $size = [math]::Round($aab.Length/1MB, 2)
    Write-Host "✅ AAB ready: $($aab.Name) ($size MB)" -ForegroundColor Green
    Write-Host "📍 Location: $($aab.FullName)" -ForegroundColor Cyan
} else {
    Write-Host "⚠️ No AAB found. Need to create signing key first." -ForegroundColor Yellow
    Write-Host "   To create a signing key, run:" -ForegroundColor White
    Write-Host "   keytool -genkeypair -v -keystore my-upload-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000" -ForegroundColor Cyan
}

# 2. Signing Keys Verification
Write-Host "`n2️⃣ SIGNING KEYS:" -ForegroundColor Cyan
Write-Host "⚠️ Ensure you have:" -ForegroundColor Yellow
Write-Host "   • Upload key (if using Google Play App Signing)" -ForegroundColor White
Write-Host "   • Or signing key configured in build.gradle" -ForegroundColor White

# 3. Version Check
Write-Host "`n3️⃣ VERSION CHECK:" -ForegroundColor Cyan
if (Test-Path "D:\AIDD\ai-humanoid-app\android\app\build.gradle") {
    $buildGradle = Get-Content "D:\AIDD\ai-humanoid-app\android\app\build.gradle" -Raw
    if ($buildGradle -match 'versionCode (\d+)') {
        Write-Host "✅ Version Code: $($Matches[1])" -ForegroundColor Green
    }
    if ($buildGradle -match "versionName ['\""]([^'\""]+)['\""]") {
        Write-Host "✅ Version Name: $($Matches[1])" -ForegroundColor Green
    }
}

# 4. Google Play Console Steps
Write-Host "`n4️⃣ UPLOAD STEPS:" -ForegroundColor Cyan
Write-Host "1. Go to: https://play.google.com/console" -ForegroundColor White
Write-Host "2. Select your app" -ForegroundColor White
Write-Host "3. Go to Production → Create new release" -ForegroundColor White
Write-Host "4. Upload the AAB file" -ForegroundColor White
Write-Host "5. Fill in release notes" -ForegroundColor White
Write-Host "6. Review and publish" -ForegroundColor White

Write-Host "`n🎯 DEPLOYMENT READY!" -ForegroundColor Green