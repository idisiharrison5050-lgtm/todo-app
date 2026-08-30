# MVP Scope and Acceptance Criteria

## Core user journey

A user can install the app, create an account, sign in, create a task, optionally assign a reminder, receive the reminder on their phone, mark the task complete, and see the same state after signing in on another supported device.

## Task acceptance criteria

- User can create a task with a title.
- User can optionally add description, due date/time, priority, and category.
- User can edit a task they own.
- User can mark a task complete/incomplete.
- User can delete a task they own.
- Tasks remain available after app restart.
- Tasks created offline are retained and synchronize after connectivity returns.

## Reminder acceptance criteria

- User can create a one-time reminder.
- User can create a recurring reminder using supported recurrence choices.
- User can enable/disable a reminder.
- User can edit/delete a reminder.
- A scheduled notification appears at the intended local time within platform scheduling constraints.
- Notification tap opens the relevant task.
- User can snooze a reminder.
- Stale notifications are cancelled after reminder deletion or schedule changes.
- Reminder schedules survive normal app restarts and are restored when necessary.

## Account acceptance criteria

- User can register and authenticate.
- Protected data requires authentication.
- User can only access their own tasks/reminders.
- Logout invalidates the local authenticated session appropriately.
- Password reset is protected against abuse.

## Design acceptance criteria

- Premium, coherent design system.
- Fast capture path for simple tasks.
- Clear Today and Upcoming views.
- Responsive layouts for supported phones.
- Accessible controls and labels.
- Light/dark treatment must maintain contrast if both are shipped.
- No critical flow depends on color alone.

## Reliability acceptance criteria

- Core task operations work offline.
- Sync is retry-safe.
- Repeated requests do not create duplicate records.
- Conflict behavior is deterministic and documented.
- App handles denied notification permission gracefully.
- App handles cold start from a notification tap.
- App handles network loss during mutations.

## Non-functional MVP requirements

- No secrets in source control.
- HTTPS in production.
- Server-side authorization on every protected resource.
- Automated tests for authentication, ownership, CRUD, reminders, and synchronization.
- Dependency security checks.
- Production-safe logging and error handling.
- Backup and restore strategy documented before private beta.
