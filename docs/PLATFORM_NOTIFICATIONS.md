# Platform Notification Requirements

## Product rule

Reminders are a core function. A reminder must not be considered complete merely because a server record exists. The app must create and maintain a device-local schedule and verify the scheduling operation succeeded where the platform API permits.

## iOS

Use UserNotifications for local reminders. Request authorization only when the user reaches reminder functionality or an intentional notification-onboarding step. Apple requires authorization for alerts/sounds/badges and lets users change settings at any time; the app must re-check authorization state before relying on notifications.

Notification actions should be designed around useful, low-friction interactions such as Done and Snooze. Tapping a notification must deep-link to the corresponding task. Notification payloads must contain only what is necessary and should avoid sensitive content where lock-screen exposure is a concern.

Do not assume arbitrary background execution. Prefer OS-supported scheduled local notifications for fixed reminder times.

## Android

Android 13/API 33+ requires `POST_NOTIFICATIONS` for non-exempt notifications. Request it contextually, after explaining the value of reminders. If denied, tasks must continue to function and the user must have a clear path to notification settings.

Use notification channels/categories appropriate to reminder urgency. Do not create excessive channels. Avoid high-priority/urgent behavior unless the reminder genuinely requires interruption.

Do not assume unrestricted background execution. Local schedules should use supported platform scheduling mechanisms and be resilient to app restart. Device/vendor battery optimization behavior must be included in QA.

## Timezone

Recurring reminders are interpreted in the user's selected IANA timezone. A device timezone change must trigger schedule reconciliation. DST transitions require explicit tests.

## Permission UX

Never request notification permission simply because the app launched. Explain the feature first, then request the system permission. If the user declines, do not repeatedly nag them; provide a settings path when they choose to enable reminders later.

## Privacy

Notification previews can reveal private task text. The app should offer a privacy-conscious notification setting and keep notification content minimal by default where appropriate.

## Reliability

The notification scheduler must be idempotent. Reconciliation should be safe to run after login, sync, app launch, timezone changes, permission changes, and reminder edits. Old schedules must be removed when reminders are deleted/disabled/changed.
