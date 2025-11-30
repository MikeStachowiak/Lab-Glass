# Installing Flutter on Windows

## Quick Install Steps

### 1. Download Flutter SDK
- Go to: https://docs.flutter.dev/get-started/install/windows
- Download the latest stable release ZIP file
- Or direct link: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip

### 2. Extract Flutter
```
1. Create folder: C:\flutter
2. Extract the downloaded ZIP to C:\flutter
3. You should have: C:\flutter\bin\flutter.bat
```

### 3. Add to System PATH
```
1. Press Win + R, type: sysdm.cpl
2. Click "Advanced" tab
3. Click "Environment Variables"
4. Under "User variables", find "Path" and click "Edit"
5. Click "New" and add: C:\flutter\bin
6. Click OK on all dialogs
7. Close and reopen PowerShell/Command Prompt
```

### 4. Install Android SDK
Option A - Install Android Studio (Recommended):
```
1. Download: https://developer.android.com/studio
2. Install Android Studio
3. Open Android Studio → Settings → SDK Manager
4. Install Android SDK (API 34)
5. Install Android SDK Build-Tools
6. Install Android SDK Platform-Tools
```

Option B - Command Line Tools Only:
```
1. Download: https://developer.android.com/studio#command-line-tools-only
2. Extract to C:\Android\cmdline-tools\latest
3. Add to PATH: C:\Android\cmdline-tools\latest\bin
4. Run: sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### 5. Accept Android Licenses
Open PowerShell and run:
```powershell
flutter doctor --android-licenses
```
Press 'y' for all prompts.

### 6. Verify Installation
```powershell
flutter doctor
```

You should see checkmarks for:
- ✓ Flutter
- ✓ Android toolchain
- ✓ Android Studio (optional)

### 7. Build the APK
```powershell
cd "C:\Users\macks\Desktop\Lab Glassess\glasses_app"
flutter pub get
flutter build apk --release
```

## Troubleshooting

### "flutter" is not recognized
- Restart PowerShell after adding to PATH
- Or use full path: `C:\flutter\bin\flutter.bat`

### Android SDK not found
- Set ANDROID_HOME environment variable:
  ```
  ANDROID_HOME = C:\Users\<your-username>\AppData\Local\Android\Sdk
  ```

### Build fails with Java errors
- Install JDK 17: https://adoptium.net/
- Set JAVA_HOME to the JDK folder

## Alternative: Use Pre-built APK

If you can't install Flutter, I can provide alternative options:
1. Use a cloud build service (Codemagic, GitHub Actions)
2. Use a Docker container with Flutter
3. Build on a different machine and transfer the APK

