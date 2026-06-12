# MedInfo App

A Flutter medicine information and reminder app with Firebase support.

## Overview

MedInfo is built with Flutter and includes features for medicine search, symptom guidance, user authentication, notifications, and reminders.

## Features

- Firebase Authentication and Firestore data storage
- Medicine search and category browsing
- Symptom-based medicine recommendations
- Medicine details and reminder scheduling
- Local settings with `shared_preferences`
- Push notifications via `firebase_messaging`
- Cross-platform support for Android, iOS, Web, and Windows

## Project structure

- `lib/` — Flutter application source code
- `android/`, `ios/`, `web/`, `windows/` — platform-specific build folders
- `assets/` — app icons and image assets
- `pubspec.yaml` — dependencies and Flutter configuration
- `.gitignore` — ignore rules for generated files and build artifacts

## Run locally

1. Install Flutter and ensure `flutter doctor` passes.
2. Run `flutter pub get`.
3. Connect a device or start an emulator.
4. Run `flutter run`.

## Firebase configuration

This project includes Firebase setup files for Android and iOS. If you update Firebase settings, verify:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `.env` for any environment variables used by `flutter_dotenv`

## Notes

- This repository is tracked on GitHub at `https://github.com/farhanarahaman976/MedInfo-App`
- Use `flutter clean` if build issues occur after dependency or config changes
