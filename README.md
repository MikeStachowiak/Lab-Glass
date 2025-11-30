# Smart Glasses Bluetooth App

A Flutter mobile app for Android to connect with smart glasses via Bluetooth and stream video.

## Features

- 🔍 **Scan for Devices** - Discover nearby Bluetooth glasses
- 🔗 **Connect via BLE** - Establish stable Bluetooth Low Energy connection
- 📹 **Video Streaming** - Stream live video from glasses camera
- 📷 **Take Photos** - Capture photos remotely
- 🎥 **Record Video** - Start/stop video recording on glasses
- 🔋 **Battery Monitor** - Real-time battery status
- 📊 **Media Stats** - View photo/video/audio counts on device

## Requirements

- Android 5.0 (API 21) or higher
- Bluetooth Low Energy support
- Location permission (required for BLE scanning)

## Building the APK

### Prerequisites

1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0.0+)
2. Install Android Studio or Android SDK
3. Accept Android licenses: `flutter doctor --android-licenses`

### Build Steps

```bash
# Navigate to project directory
cd glasses_app

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Or build debug APK for testing
flutter build apk --debug
```

### Output Location

The built APK will be at:
- Release: `build/app/outputs/flutter-apk/app-release.apk`
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`

## Installation

1. Transfer the APK to your Android phone
2. Enable "Install from Unknown Sources" in settings
3. Tap the APK file to install
4. Grant Bluetooth and Location permissions when prompted

## Usage

1. **Scan** - Tap "SCAN" to search for glasses
2. **Connect** - Tap on your glasses device to connect
3. **Control** - Use quick actions to take photos/videos
4. **Stream** - Tap "VIDEO STREAM" for live camera feed

## Supported Glasses Protocol

This app implements the QC SDK Bluetooth protocol:
- Service UUID: `0000ae00-0000-1000-8000-00805f9b34fb`
- Commands for photo, video, audio, and streaming modes
- Battery and firmware info retrieval
- Media file management

## Troubleshooting

- **Can't find device**: Ensure glasses are powered on and in pairing mode
- **Connection fails**: Try toggling Bluetooth off/on
- **No video**: Glasses must support video streaming over BLE
- **Permissions denied**: Grant all requested permissions in Settings

## License

MIT License - Free for personal and commercial use.

