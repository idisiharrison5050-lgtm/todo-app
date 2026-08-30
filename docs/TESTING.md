# Testing Strategy

## Test levels

### Unit

Test pure business rules, especially reminder recurrence, timezone conversion, snooze calculations, validation, and synchronization conflict rules.

### Backend feature/API

Test authenticated and unauthenticated requests, CRUD, authorization, validation, rate limits, idempotency, and sync behavior.

### Mobile unit/widget

Test state management, task rendering, forms, filters, error states, notification navigation, and permission flows.

### Integration

Test real API + database behavior and critical mobile-to-server journeys.

## Critical scenarios

1. Register and sign in.
2. Create a task online.
3. Create a task offline.
4. Reconnect and synchronize.
5. Schedule a one-time reminder.
6. Schedule a daily reminder.
7. Schedule a weekly reminder.
8. Edit a reminder.
9. Delete a reminder.
10. Snooze a reminder.
11. Tap a notification.
12. Kill/restart the app.
13. Reboot the device.
14. Deny notification permission.
15. Change timezone.
16. Cross midnight with a reminder.
17. Test DST transition behavior.
18. Two devices edit the same task.
19. Replay the same mutation.
20. Attempt cross-user resource access.

## Device matrix

### iOS

Validate representative current and minimum-supported iOS versions and multiple screen sizes. Include at least one physical device because simulator behavior is not sufficient for notification/background validation.

### Android

Validate representative current and minimum-supported Android versions, multiple manufacturers where practical, multiple screen sizes, and at least one physical device. Test battery optimization/background restrictions because behavior varies by device/vendor.

## Accessibility

Test with VoiceOver on iOS and TalkBack on Android. Validate text scaling, focus order, labels, contrast, touch target sizing, and reduced-motion behavior.

## Reliability

Test network loss, slow network, airplane mode, app process death, device reboot, stale local data, server errors, duplicate requests, and interrupted synchronization.

## Security

Verify:
- User A cannot access User B data.
- Tokens are not logged.
- Secrets are absent from builds/repository.
- Authentication is rate limited.
- Invalid payloads are rejected.
- Ownership cannot be overridden by request data.
- Replay/idempotency behavior is safe.
- Production errors do not leak stack traces.

## Release gate

Critical-path tests must pass before private device beta. No unresolved critical/high security issue may remain. Public store submission requires a final platform compliance and privacy review.
