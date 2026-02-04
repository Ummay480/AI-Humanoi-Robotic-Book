# Android Build Guide for AI Humanoid App

## Prerequisites
- Java Development Kit (JDK) 11 or higher
- Android Studio with Android SDK
- Capacitor CLI installed globally (`npm install -g @capacitor/cli`)

## Step 1: Generate Keystore for Signing

Run the following command to generate a keystore for signing your app:

```bash
keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Move the generated keystore to the correct location:
```bash
mv upload-keystore.jks D:\AIDD\ai-humanoid-app\android\app\keys\
```

## Step 2: Set Environment Variables (Optional but Recommended)

Set these environment variables for automated builds:

```bash
export KEYSTORE_PATH="D:/AIDD/ai-humanoid-app/android/app/keys/upload-keystore.jks"
export KEYSTORE_PASSWORD="your_keystore_password"
export KEY_ALIAS="upload"
export KEY_PASSWORD="your_key_password"
```

On Windows:
```cmd
set KEYSTORE_PATH=D:\AIDD\ai-humanoid-app\android\app\keys\upload-keystore.jks
set KEYSTORE_PASSWORD=your_keystore_password
set KEY_ALIAS=upload
set KEY_PASSWORD=your_key_password
```

## Step 3: Prepare for Production Build

1. Make sure your `www` folder contains your production-ready web app
2. Update the capacitor.config.json if needed
3. Sync Capacitor with Android:

```bash
npx cap sync android
```

## Step 4: Build Signed AAB for Google Play Store

### Option 1: Using Gradle Wrapper (Recommended)

Navigate to the Android directory and run:

```bash
cd D:\AIDD\ai-humanoid-app\android
./gradlew bundleRelease
```

On Windows:
```cmd
cd D:\AIDD\ai-humanoid-app\android
gradlew.bat bundleRelease
```

The signed AAB file will be located at:
`D:\AIDD\ai-humanoid-app\android\app\build\outputs\bundle\release\app-release.aab`

### Option 2: Using Android Studio

1. Open `D:\AIDD\ai-humanoid-app\android` in Android Studio
2. Go to Build > Generate Signed Bundle / APK
3. Choose "Android App Bundle"
4. Select your keystore file and enter credentials
5. Select "release" build variant
6. Click "Finish"

## Step 5: Verify Your Build

Check that your AAB file was created successfully:
```bash
ls -la D:\AIDD\ai-humanoid-app\android\app\build\outputs\bundle\release\
```

## Troubleshooting

### Issue: Gradle sync problems in Android Studio
Solution: Close Android Studio, delete `.gradle` folders in the project, then reopen and sync.

### Issue: Build fails due to missing signing config
Solution: Make sure you have the keystore in the correct location and environment variables set.

### Issue: App crashes on device
Solution: Check LogCat in Android Studio for error messages. Ensure all Capacitor plugins are properly installed with `npx cap sync`.

## Additional Notes

- The app uses local assets from the `www` folder, not the remote URL
- ProGuard rules are optimized for Capacitor apps
- Build optimizations (minifyEnabled, shrinkResources) are enabled for release builds
- The app supports offline functionality since it bundles web assets locally