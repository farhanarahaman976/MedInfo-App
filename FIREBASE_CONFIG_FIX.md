# Firebase Configuration Error Fix

## Error: "[firebase_auth/unknown] An internal error has occurred [configuration not found]"

This error means Flutter cannot find or load your Firebase configuration. Here's how to fix it:

## Quick Fix (Most Common Solution)

### Step 1: Clean and Rebuild
```bash
cd e:\MedInfo
flutter clean
flutter pub get
flutter run
```

### Step 2: Verify google-services.json

**Location:** `android/app/google-services.json`

Should look like this (check these values match your Firebase project):
```json
{
  "project_info": {
    "project_number": "563072773656",
    "project_id": "medinfo-86a58"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:563072773656:android:558ed7d10bf1a223a75d6d",
        "android_client_info": {
          "package_name": "com.company.medinfo"
        }
      },
      "api_key": [
        {
          "current_key": "AIzaSyA8zcHiddNA1fS70chCstiFCNinXAZePbo"
        }
      ]
    }
  ]
}
```

**Critical:** Package name must match: `com.company.medinfo`

### Step 3: Verify Android Build Configuration

**File:** `android/app/build.gradle.kts`

Should contain:
```
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // ← This is CRITICAL
    id("dev.flutter.flutter-gradle-plugin")
}
```

**If missing "com.google.gms.google-services"**, add it to the plugins section.

### Step 4: Force Rebuild APK

```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

## If Still Not Working

### Solution A: Download google-services.json Again

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **medinfo-86a58**
3. Go to **Project Settings** (gear icon)
4. Select **Your apps** tab
5. Find **Android** app: `com.company.medinfo`
6. Click **google-services.json** to download
7. Replace the file at `android/app/google-services.json`
8. Run `flutter clean && flutter run`

### Solution B: Verify Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/project/medinfo-86a58)
2. **Authentication:**
   - Click "Get Started"
   - Enable "Email/Password" provider
3. **Firestore Database:**
   - Click "Create database"
   - Start in test mode (you already set rules)
   - Create collection "users"
4. **Project Settings:**
   - Copy **Project ID**: Should be `medinfo-86a58`
   - Check API keys are configured

### Solution C: Check Package Name Match

Your app's package name in Firebase Console must exactly match `com.company.medinfo`

**Verify in Android manifest:**
File: `android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application ...>
        <!-- Package is set in build.gradle.kts as applicationId -->
```

**Verify in build config:**
File: `android/app/build.gradle.kts`
```kotlin
defaultConfig {
    applicationId = "com.company.medinfo"  // ← Must match Firebase
    ...
}
```

## Detailed Troubleshooting

### Symptoms & Solutions

| Error | Cause | Fix |
|-------|-------|-----|
| `configuration not found` | google-services.json missing or invalid | Download from Firebase Console |
| `internal error` | Firebase not initialized | Check main.dart initialization |
| `permission-denied` | Firestore rules blocking access | Check Firestore security rules |
| `network error` | Device can't reach Firebase | Check internet connection |

## Complete Reset (Nuclear Option)

If nothing works, do a complete reset:

```bash
# 1. Clean everything
flutter clean
cd android
gradlew clean
cd ..
rm -rf build/
rm -rf .dart_tool/

# 2. Download dependencies
flutter pub get

# 3. Rebuild from scratch
flutter run
```

## Verify Everything Works

1. **Check logs:**
   ```
   flutter run
   # Look for: ✓ Firebase initialized successfully
   # Look for: ✓ Firestore offline persistence enabled
   ```

2. **Test registration:**
   - Go to Profile tab
   - Click Register
   - Use test email: `test@example.com`
   - Set password: `password123`
   - Fill other fields

3. **Should see:**
   - ✓ Firebase Auth user created
   - ✓ User data saved to Firestore successfully
   - Auto-redirect to home page

## Firebase Project Details

- **Project ID:** medinfo-86a58
- **Package Name:** com.company.medinfo
- **Firestore:** medinfo-86a58 (us-central1)
- **API Key:** AIzaSyA8zcHiddNA1fS70chCstiFCNinXAZePbo

## Important Firestore Rules

Should be set to:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow create, read, update, delete: if request.auth.uid == userId;
    }
    match /medicines/{document=**} {
      allow read;
    }
  }
}
```

## Still Stuck?

Share the full error message from:
```bash
flutter run
# And from Android Studio logcat, search for "Firebase"
```
