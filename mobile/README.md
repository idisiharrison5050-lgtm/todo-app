# Todo Mobile MVP

A local-first Flutter todo app with scheduled Android reminders.

## MVP behavior

- Create, edit, complete and delete tasks.
- Tasks persist locally on supported mobile platforms.
- A task with a due date/time automatically gets a one-time reminder.
- The reminder can be switched off per task.
- Repeating reminders are optional.
- Editing a task replaces its previous scheduled reminder.
- Completing or deleting a task cancels its scheduled reminder.
- Notification preference is persisted on the device.
- Re-enabling notifications restores reminders for active scheduled tasks.
- Reminder times are normalized to the selected minute.
- Android reminders use exact scheduling and are configured to recover after device reboot/app replacement.

## Android verification

The first Android build may install missing SDK/NDK/CMake components and can take several minutes. Subsequent builds should normally be much faster because Gradle and Android artifacts are cached.

For a physical Android device, enable USB debugging and run:

```powershell
flutter devices
flutter run -d <device-id>
```

Keep the device connected while testing scheduled reminders. Test at least once with the screen locked and once with the screen on. Android battery optimization can affect delivery on some devices.

## Verification commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The MVP does not require an account, cloud sync, or network connection for basic task/reminder functionality.
