# Mobile Client

This directory is reserved for the Flutter iOS/Android application.

## Target

Use the current stable Flutter release approved for the project. Flutter 3.47 is the current stable release as of August 2026. Pin the SDK range in the eventual Flutter project rather than relying on an arbitrary future SDK.

## Responsibilities

- Premium task/reminder UI.
- Secure credential storage.
- Local task/reminder database.
- Offline mutation queue.
- API synchronization.
- Local notification scheduling.
- Notification actions and deep links.
- Permission UX.

## Platform requirements

### iOS

Use Apple's UserNotifications APIs through a maintained Flutter notification abstraction. Request notification authorization in context, after the user understands why reminders need it. Apple requires authorization before user-facing notifications and provides local notification scheduling through UserNotifications. See the project's architecture/security docs for the exact policy. Do not request unrelated permissions in MVP.

### Android

Target a modern Android SDK. Android 13/API 33+ requires the `POST_NOTIFICATIONS` runtime permission for non-exempt notifications. Request it in context after the user understands reminders, and handle denial without breaking task management. Notification behavior must account for Android background/battery restrictions.

## Security

Never store API bearer tokens in shared preferences/plaintext files. Use platform secure storage backed by iOS Keychain and Android Keystore mechanisms. Never log tokens or private task contents.

## Build prerequisites

Flutter, Android Studio/SDK, Xcode (macOS for iOS builds), CocoaPods as required by the selected plugin set, and physical test devices for notification validation.

The mobile project should be generated in this directory during the Flutter foundation phase; this README intentionally avoids committing generated build artifacts or platform signing secrets.
