# Android Build & Deploy Assistant

This PowerShell script automates the process of building and deploying your Android app with comprehensive error checking and user-friendly output.

## Features

- ✅ Pre-checks (Java, Gradle, ADB, required files)
- ✅ Automatic cleaning and fixing of build issues
- ✅ Complete build process with detailed logging
- ✅ Interactive device selection
- ✅ Automatic app installation and launch
- ✅ Post-deployment verification
- ✅ Color-coded output for easy status identification
- ✅ Comprehensive troubleshooting guidance

## Prerequisites

1. **Java 17 or higher** installed and in PATH
2. **Android SDK** with platform tools (ADB) installed and in PATH
3. **Connected Android device** with USB debugging enabled
4. **PowerShell** with execution policy that allows script running

## How to Run

### Option 1: PowerShell (Recommended)
```powershell
# Navigate to project directory
cd D:\AIDD\ai-humanoid-app

# Run the script
.\android_build_deploy.ps1
```

### Option 2: Batch File (Easier for beginners)
```cmd
# Navigate to project directory
cd D:\AIDD\ai-humanoid-app

# Double-click android_build_deploy.bat
# OR run from command line
.\android_build_deploy.bat
```

## Command Line Options

- `-SkipPreChecks`: Skip prerequisite checks (not recommended)
- `-CleanOnly`: Perform only cleaning, no build or deploy
- `-DeviceId "device_serial"`: Deploy to specific device by serial
- `-Verbose`: Show detailed output

Example:
```powershell
.\android_build_deploy.ps1 -CleanOnly
```

## Troubleshooting

### Common Issues:

1. **Execution Policy Error**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **No Devices Found**:
   - Enable Developer Options on your Android device
   - Enable USB Debugging in Developer Options
   - Connect device via USB
   - Tap "Allow" on the USB debugging authorization popup

3. **Java Not Found**:
   - Install OpenJDK 17 or Oracle JDK 17
   - Add Java bin directory to your PATH environment variable

4. **Gradle Not Found**:
   - Install Gradle or ensure Android Studio is installed
   - Add Gradle bin directory to your PATH environment variable

5. **Build Fails**:
   - Check the generated log file for specific error messages
   - Run `npx cap sync android` to sync Capacitor plugins
   - Verify your `variables.gradle` configuration

### Device Selection:
If multiple devices are connected, the script will prompt you to select which device to deploy to.

## Script Flow

1. **Pre-checks**: Verify Java, Gradle, ADB, and required files
2. **Clean**: Stop Gradle daemons and remove old build files
3. **Fix**: Verify and create default configurations if needed
4. **Build**: Compile the Android app with detailed progress
5. **Deploy**: Install the APK to selected device
6. **Launch**: Start the app on the device
7. **Verify**: Confirm successful installation

## Output Legend

- ✅ Green: Success
- ⚠️ Yellow: Warning/Information
- ❌ Red: Error
- 🔵 Blue: Progress/Step

## Log Files

Build logs are automatically saved to files named `build_log_yyyyMMdd_HHmmss.txt` in the project root directory for troubleshooting.