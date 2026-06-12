# Registration Troubleshooting Guide

## Problem: "Registration failed. Please try again"

### Root Causes

#### 1. **Firestore Security Rules** (Most Common)
Firebase Firestore has strict default security rules that block writes. 

**Fix:** Set permissive Firestore rules for development:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `medinfo-86a58`
3. Go to **Firestore Database** → **Rules**
4. Replace the rules with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for authenticated users
    match /users/{userId} {
      allow create, read, update, delete: if request.auth.uid == userId;
    }
    
    // Allow read for everyone (for medicines, etc.)
    match /medicines/{document=**} {
      allow read;
    }
  }
}
```

5. Click **Publish**

#### 2. **Network Connectivity**
The device can't reach Firebase servers.

**Fix:**
- Check internet connection
- Ensure WiFi or mobile data is working
- Try again in a moment

#### 3. **Firebase Not Initialized**
Firebase services failed to initialize.

**Check logs:**
- Open Android Studio logcat
- Search for "Firebase" and "initialization"
- Check for initialization errors

#### 4. **User Validation**
Form data has issues.

**Check:**
- Email format is valid
- Password is at least 6 characters
- All fields are filled correctly
- Phone number format (if validation is strict)

### How to Debug

1. **Enable Logging**
   The code now prints detailed logs:
   ```
   flutter run
   # Watch logcat for "========== Registration Start =========="
   ```

2. **Check Firebase Console**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Project: `medinfo-86a58`
   - Check Authentication > Users (should see new users if registration succeeds)
   - Check Firestore > Data (should see user documents)

3. **Common Log Patterns**

   **Permission Denied:**
   ```
   ✗ Firestore error: Firestore error: Permission denied
   ```
   → **Solution:** Update Firestore security rules

   **Network Error:**
   ```
   ✗ Firestore error: Network error
   ```
   → **Solution:** Check internet connection

   **User is null:**
   ```
   Failed to create auth user: User is null
   ```
   → **Solution:** Check email format and Firebase Auth status

### Step-by-Step Verification

1. **Check Firebase Project ID**
   - Expected: `medinfo-86a58`
   - File: `android/app/google-services.json`

2. **Check API Key**
   - Expected: `AIzaSyA8zcHiddNA1fS70chCstiFCNinXAZePbo`
   - File: `android/app/google-services.json`

3. **Verify Services Enabled**
   - Go to Firebase Console > Project Settings
   - Ensure Firebase Auth is enabled
   - Ensure Cloud Firestore is enabled

4. **Test Registration**
   - Use test email: `test@example.com`
   - Use test password: `password123`
   - Fill other fields with any valid data
   - Watch the logs for detailed error messages

### Files Modified for Better Error Handling

1. `lib/services/firebase_user_service.dart`
   - Added detailed logging at each step
   - Better error messages with context

2. `lib/pages/register_page.dart`
   - Improved error message display
   - Shows actual errors for debugging
   - Longer toast duration (6 seconds)

### Production Security

**Important:** Before deploying, update Firestore rules to be more restrictive:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only allow authenticated users to write their own data
    match /users/{userId} {
      allow create: if request.auth.uid == null || request.auth.uid == userId;
      allow read, update, delete: if request.auth.uid == userId;
    }
    
    // Allow public read access to medicines
    match /medicines/{document=**} {
      allow read;
    }
  }
}
```

### Still Having Issues?

1. **Check Browser Console** (if testing on web)
2. **Clear Cache** - `flutter clean && flutter pub get`
3. **Rebuild** - `flutter run`
4. **Check logcat** - `adb logcat | grep Flutter`
5. **Contact Support** - Share the full error message from logs

### Firebase Console URLs

- **Project:** https://console.firebase.google.com/project/medinfo-86a58
- **Authentication:** https://console.firebase.google.com/project/medinfo-86a58/authentication
- **Firestore:** https://console.firebase.google.com/project/medinfo-86a58/firestore
- **Settings:** https://console.firebase.google.com/project/medinfo-86a58/settings/general
