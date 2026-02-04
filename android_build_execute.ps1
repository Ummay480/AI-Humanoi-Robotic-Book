# Set the correct Java home
$env:JAVA_HOME = "C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot"

# Add Java bin to PATH
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# Change to android directory
Set-Location -Path "D:\AIDD\ai-humanoid-app\android"

Write-Host "Java Home: $env:JAVA_HOME" -ForegroundColor Green
Write-Host "Java Version:" -ForegroundColor Green

# Verify Java
& "$env:JAVA_HOME\bin\java.exe" -version

Write-Host "Stopping Gradle daemons..." -ForegroundColor Yellow
.\gradlew.bat --stop

Write-Host "Cleaning project..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "build", "app\build", ".gradle" -ErrorAction SilentlyContinue

Write-Host "Building debug APK..." -ForegroundColor Cyan
.\gradlew.bat clean assembleDebug --no-daemon --stacktrace