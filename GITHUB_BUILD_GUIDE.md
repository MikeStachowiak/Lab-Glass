# Build APK Using GitHub Actions (Cloud Build)

This guide shows you how to build the APK in the cloud **without installing anything** on your computer.

## 🚀 Quick Start (5 minutes)

### Step 1: Create a GitHub Account
If you don't have one: https://github.com/join

### Step 2: Create a New Repository
1. Go to: https://github.com/new
2. Repository name: `smart-glasses-app`
3. Select **Private** (recommended) or Public
4. Click **Create repository**

### Step 3: Upload the Code
**Option A - Using GitHub Web Interface (Easiest):**

1. On your new repository page, click **"uploading an existing file"**
2. Drag and drop the entire `glasses_app` folder contents
3. Click **Commit changes**

**Option B - Using Git Command Line:**

```bash
cd "C:\Users\macks\Desktop\Lab Glassess\glasses_app"
git init
git add .
git commit -m "Initial commit - Smart Glasses App"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/smart-glasses-app.git
git push -u origin main
```

### Step 4: Run the Build
1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You'll see "Build Android APK" workflow
4. Click **Run workflow** → **Run workflow** (green button)
5. Wait 3-5 minutes for the build to complete ✅

### Step 5: Download Your APK
1. Click on the completed workflow run
2. Scroll down to **Artifacts**
3. Click **smart-glasses-release-apk** to download
4. Extract the ZIP file
5. Transfer `app-release.apk` to your phone and install!

---

## 📱 Installing the APK on Your Phone

### Method 1: Direct Transfer
1. Connect phone to PC via USB
2. Copy `app-release.apk` to phone's Download folder
3. On phone, open Files app and tap the APK
4. Enable "Install from unknown sources" if prompted
5. Tap Install

### Method 2: Cloud Storage
1. Upload APK to Google Drive / Dropbox
2. Open the link on your phone
3. Download and install

### Method 3: Email
1. Email the APK to yourself
2. Open email on phone
3. Download attachment and install

---

## 🔄 Rebuilding After Changes

Every time you push changes to GitHub, the APK will automatically rebuild:

```bash
git add .
git commit -m "Updated feature X"
git push
```

Or manually trigger a build:
1. Go to **Actions** tab
2. Click **Build Android APK**
3. Click **Run workflow**

---

## ⚙️ Workflow Features

| Feature | Description |
|---------|-------------|
| **Auto Build** | Builds on every push to main/master |
| **Manual Trigger** | Can be started manually anytime |
| **Release APK** | Optimized, smaller file size |
| **Debug APK** | For testing with debug info |
| **30-day Storage** | APKs kept for 30 days |
| **Caching** | Flutter cached for faster builds |

---

## 🐛 Troubleshooting

### Build Failed?
1. Click on the failed workflow run
2. Expand the failed step to see error details
3. Common fixes:
   - Check `pubspec.yaml` for typos
   - Ensure all files were uploaded
   - Check the `.github/workflows/build-apk.yml` exists

### Can't Find Artifacts?
- Artifacts appear only after successful builds
- Check the workflow completed with ✅ green checkmark
- Artifacts expire after 30 days

### APK Won't Install?
- Enable "Install from unknown sources" in Settings
- Make sure you downloaded the full APK (not a partial download)
- Try the debug APK if release doesn't work

---

## 📋 File Checklist

Make sure these files are in your repository:

```
glasses_app/
├── .github/
│   └── workflows/
│       └── build-apk.yml     ← GitHub Actions workflow
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       └── AndroidManifest.xml
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── .gitignore
├── analysis_options.yaml
└── pubspec.yaml
```

---

## 🎉 Done!

Once you have the APK on your phone:
1. Install the app
2. Grant Bluetooth & Location permissions
3. Turn on your glasses
4. Tap **SCAN** to find and connect!

Need help? Create an issue on your GitHub repository.

