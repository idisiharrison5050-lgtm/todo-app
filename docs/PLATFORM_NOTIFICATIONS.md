# Platform Notification Requirements

## Product rule

Reminders are a core function. A reminder is not complete merely because a server record exists. The mobile app must create and maintain a device-local schedule and verify scheduling success where the platform API permits.

## iOS

Use Apple's UserNotifications APIs through the Flutter notification layer. Request authorization only when the user reaches reminder functionality or an intentional notification-onboarding step. Re-check authorization because users can change notification settings at any time.

Use stable notification identifiers so schedules can be cancelled/replaced deterministically. Notification actions should support useful interactions such as Done and Snooze. Tapping a notification must deep-link to the corresponding task. Payloads should contain only what is necessary and avoid sensitive content where lock-screen exposure is a concern.

Do not assume arbitrary background execution. Prefer OS-supported scheduled local notifications for fixed reminder times.

Before App Store release, validate notification behavior on physical iPhones across supported OS versions, including reboot, Focus modes, notification settings changes, timezone changes, and permission changes.

## Android

Android 13/API 33+ requires `POST_NOTIFICATIONS` for non-exempt notifications. Request it contextually, after explaining the value of reminders. If denied, tasks must continue to function and the user must have a clear path to notification settings.

Use stable notification channels/categories appropriate to reminder urgency. Do not create excessive channels. Avoid high-priority/urgent behavior unless the reminder genuinely requires interruption.

Do not assume unrestricted background execution. Local schedules must use supported platform scheduling mechanisms and be resilient to app restart. Test battery optimization and vendor-specific background behavior on physical devices.

Validate exact-alarm behavior against the target Android SDK and current platform policy. Do not request special alarm permissions unless a product requirement justifies them and the permission is permitted for that use case.

## Cross-platform schedule rules

- The server stores reminder intent; the device owns local notification registration.
- Scheduling must be idempotent.
- Reconciliation should be safe after login, sync, app launch, timezone changes, permission changes, and reminder edits.
- Delete or replace old schedules when reminders are deleted, disabled, or changed.
- Store timezone as an IANA identifier and interpret recurring schedules in that timezone.
- Reconcile after detected timezone changes and test DST transitions where applicable.
- Multiple reminders must have stable, collision-resistant notification identifiers.

## Permission UX

Never request notification permission simply because the app launched. Explain the feature first, then request the system permission. If declined, do not repeatedly nag the user; provide a settings path when they choose to enable reminders later.

## Privacy

Notification previews can reveal private task text. Offer a privacy-conscious notification setting and keep notification content minimal by default where appropriate.

## Reliability QA

Test: permission granted/denied/later enabled; one-time reminders; daily/weekly recurrence; snooze; edits; deletion; disabled reminders; app process death; device reboot; timezone changes; DST transitions; multiple nearby reminders; cold-start notification taps; foreground taps; Android battery restrictions; and iOS Focus/notification settings interactions.
