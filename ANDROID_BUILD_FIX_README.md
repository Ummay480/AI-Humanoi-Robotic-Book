# Android Build Fix Guide

This repository contains scripts to fix common Android build issues for the ai-humanoid-app project.

## Scripts Included

- `fix_android_build.ps1` - Main PowerShell script for fixing Android build issues
- `fix_android_build.bat` - Batch wrapper for the PowerShell script

## What the Script Does

The build fix script performs the following operations:

1. **Prerequisite Checks**
   - Verifies Java 21 installation
   - Ensures required Android project files exist

2. **Complete Cache Cleaning**
   - Stops all Gradle daemons
   - Removes `.gradle` cache directories
   - Clears build directories
   - Cleans Windows temp folder of Gradle files

3. **Java Configuration**
   - Sets Java 21 as the default JDK
   - Updates `gradle.properties` with Java 21 path
   - Disables auto-detection for stability

4. **Gradle Configuration**
   - Updates build.gradle for Java 21 compatibility
   - Ensures proper repository configuration in settings.gradle

5. **Build Operations**
   - Performs clean builds with `--no-daemon --stacktrace` flags
   - Supports both debug and release builds

## Usage

### PowerShell (Recommended)
```powershell
# Basic usage - cleans caches and attempts debug build
.\fix_android_build.ps1

# Clean only (no build)
.\fix_android_build.ps1 -CleanOnly

# Build debug APK only
.\fix_android_build.ps1 -BuildDebug

# Build release AAB only
.\fix_android_build.ps1 -BuildRelease

# Force execution even with warnings
.\fix_android_build.ps1 -Force

# Verbose output
.\fix_android_build.ps1 -VerboseOutput
```

### Batch File (Alternative)
```batch
# Run with default settings
fix_android_build.bat
```

## Common Issues Addressed

- "Could not read workspace metadata" errors
- Java version incompatibilities
- Corrupted Gradle caches
- Missing or incorrect Java home configuration
- Repository configuration issues

## Troubleshooting

If the script fails:

1. Check `build_log.txt` for detailed logs
2. Check `build_error_*.txt` for specific error outputs
3. Ensure Java 21 is installed at the expected location:
   `C:\Users\HC\AppData\Local\Programs\Eclipse Adoptium\jdk-21.0.9.10-hotspot`
4. Run with `-Force` flag to bypass some safety checks
5. Run as Administrator if file permission issues occur

## Expected Output

After successful execution:
- Debug APK will be in `app/build/outputs/apk/debug/`
- Release AAB will be in `app/build/outputs/bundle/release/`
- Log files will be created in the project root