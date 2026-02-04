# ANDROID BUILD FIX INSTRUCTIONS

## OVERVIEW
This PowerShell script completely fixes Android build issues by:
1. Clearing all Gradle caches and daemons
2. Setting up Java 21 properly
3. Fixing repository configurations
4. Building the project successfully

## PREREQUISITES
- Java 21 must be installed (Eclipse Adoptium recommended)
- Node.js and npm installed
- Capacitor project set up in D:\AIDD\ai-humanoid-app

## HOW TO RUN

### Option 1: Standard Run (Recommended)
```powershell
# Navigate to project root
cd D:\AIDD\ai-humanoid-app

# Run the fix script
.\android_build_fix.ps1
```

### Option 2: Verbose Output
```powershell
.\android_build_fix.ps1 -VerboseOutput
```

### Option 3: Force Run (Even if prerequisites fail)
```powershell
.\android_build_fix.ps1 -Force
```

### Option 4: Dry Run (See what would happen)
```powershell
.\android_build_fix.ps1 -DryRun
```

## TROUBLESHOOTING

### If Java 21 is not found:
1. Download Java 21 from https://adoptium.net/
2. Install to default location
3. Run the script again

### If you get permission errors:
1. Right-click PowerShell and select "Run as administrator"
2. Navigate to the project directory
3. Run the script again

### If build still fails:
1. Check the generated log files:
   - build_log.txt (main log)
   - build_output.txt (build output)
   - build_error.txt (error details)
2. Run Gradle with more verbose output:
   ```cmd
   cd android
   .\gradlew assembleDebug --info --stacktrace
   ```

## EMERGENCY ROLLBACK

If something goes wrong, you can restore your original files:
1. Make backups before running: `cp gradle.properties gradle.properties.backup`
2. Or restore from version control if available

## POST-BUILD VERIFICATION

After successful build:
1. APK will be in `android\app\build\outputs\apk\debug\`
2. Run `npx cap sync android` if you added new plugins
3. Open Android Studio and import the `android` folder if needed

## COMMON ISSUES FIXED BY THIS SCRIPT

- ✅ Invalid Java path errors
- ✅ Java version conflicts
- ✅ Cached Gradle configuration issues
- ✅ Repository preference warnings
- ✅ Capacitor build failures
- ✅ Gradle daemon conflicts
- ✅ Plugin compatibility issues

## SUPPORTED ENVIRONMENTS
- Windows 10/11
- PowerShell 5.1 or later
- Java 21 (Eclipse Adoptium recommended)
- Gradle 8.0+
- Capacitor 6.x

## RECOMMENDED WORKFLOW
1. Close Android Studio
2. Close any running Gradle processes
3. Run this script
4. Reopen Android Studio after successful build