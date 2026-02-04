#!/bin/bash
# Build script for AI Humanoid App Android release

echo "Starting Android release build for AI Humanoid App..."

# Navigate to project directory
cd "$(dirname "$0")"

# Sync Capacitor with Android
echo "Syncing Capacitor with Android..."
npx cap sync android

# Navigate to Android directory
cd android

# Build the release AAB
echo "Building release AAB..."
./gradlew bundleRelease

echo "Build completed!"
echo "Find your AAB file at: $(pwd)/app/build/outputs/bundle/release/app-release.aab"

# Optional: Open the output directory
explorer.exe "$(pwd)/app/build/outputs/bundle/release/"