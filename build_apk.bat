@echo off
echo ============================================
echo    Smart Glasses App - APK Builder
echo ============================================
echo.

REM Check if Flutter is in PATH
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    echo.
    echo Please install Flutter first:
    echo 1. Download from: https://flutter.dev/docs/get-started/install/windows
    echo 2. Extract to C:\flutter
    echo 3. Add C:\flutter\bin to your PATH
    echo 4. Run this script again
    echo.
    pause
    exit /b 1
)

echo [1/4] Flutter found! Checking version...
flutter --version
echo.

echo [2/4] Getting dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies!
    pause
    exit /b 1
)
echo.

echo [3/4] Running Flutter doctor...
flutter doctor
echo.

echo [4/4] Building Release APK...
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] Release build failed, trying debug build...
    flutter build apk --debug
)
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ============================================
    echo    BUILD SUCCESSFUL!
    echo ============================================
    echo.
    echo APK Location:
    echo   build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Copy this file to your phone and install it!
    echo.
    explorer "build\app\outputs\flutter-apk"
) else if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ============================================
    echo    DEBUG BUILD SUCCESSFUL!
    echo ============================================
    echo.
    echo APK Location:
    echo   build\app\outputs\flutter-apk\app-debug.apk
    echo.
    explorer "build\app\outputs\flutter-apk"
) else (
    echo [ERROR] Build failed! Check the error messages above.
)

echo.
pause

