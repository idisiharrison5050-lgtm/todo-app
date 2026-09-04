# AI Continuation Brief

This file is the durable handoff for future development sessions. Read it before making major changes.

## Product bar

This is not intended to remain a basic todo app. The target is a premium, best-in-class consumer productivity product with the polish expected from products associated with companies such as Apple or Samsung.

Add features when they materially improve usefulness, reliability, delight, or competitive differentiation. Do not add novelty features merely to increase the feature count.

## Architecture

- Backend: Laravel 13 / PHP 8.3+
- Mobile: Flutter 3.47.2, iOS + Android
- Backend owns authentication, authorization, server persistence, sync/security boundary, versions, idempotency, and deletion semantics.
- Mobile owns UI, local persistence, offline mutation queue, local notification scheduling, and device interaction.
- Mobile authentication uses Laravel Sanctum bearer tokens stored only in OS-backed secure storage.
- API is versioned under `/api/v1`.
- Reminder scheduling is timezone-aware and must remain correct across recurrence, DST, device restart, and timezone changes.

## Current development branch

`feature/sync-engine-v2`

## Recent implemented work

- Fixed workspace widget tests to match the redesigned navigation and Today data behavior.
- Allowed editing an existing overdue task without forcing a future schedule.
- Added recurring-task catch-up so missed recurrence occurrences advance to the next future occurrence.
- Added regression coverage for overdue editing and recurrence catch-up.
- Established a restrained premium visual theme with light/dark support and refined Material 3 components.
- Redesigned task details around stronger hierarchy, completion state, status pills, detail metadata, notes, subtasks/checklists, and activity history.
- Redesigned task creation/editing around a focused capture flow, quick scheduling, reminders, advanced options, and a live save summary.

## Immediate engineering priorities

1. Verify the latest mobile UI changes compile cleanly and preserve existing task/reminder behavior.
2. Remove the dynamic `Map<String, dynamic>` argument passing in the add/edit task flow where practical; use typed calls so compile-time safety is preserved.
3. Review completion error handling. Optimistic completion must not silently hide persistence or notification-scheduling failures.
4. Finish task quick actions: complete, favorite, snooze, reschedule, delete, undo, and safe destructive confirmation where needed.
5. Finish the Home/Today experience with meaningful progress, overdue attention, smart grouping, fast actions, and excellent empty/loading/error states.
6. Finish Calendar with useful month/week/day planning and safe rescheduling behavior without breaking timezone semantics.
7. Make Focus a real focused workflow rather than a decorative screen: session state, current task, timer, completion, pause/resume, and useful history.
8. Complete global search/filter/sort/organization behavior across title, notes, category, tags, priority, favorite, completion, due date, and smart views.
9. Surface sync state clearly: syncing, offline, queued changes, retry, and conflict outcomes. Never expose tokens or sensitive server data in logs.
10. Complete notification lifecycle UX and verification: permission handling, exact timing, recurring reminders, snooze, complete actions, background handling, restart/cold-start handling, and privacy-safe notification content.

## Reliability and verification priorities

- Two-device sync conflict integration tests.
- Offline mutation queue and reconnect verification.
- Deletion tombstone edge cases.
- Retry/idempotency behavior under duplicate and concurrent requests.
- Timezone/DST matrix, including daylight-saving transitions and timezone changes.
- Physical Android notification testing and then physical iOS testing.
- Accessibility semantics, text scaling, contrast, touch targets, keyboard/focus behavior, and screen-reader navigation.
- Broader widget/component tests and critical journey integration tests.
- OWASP-style API review, dependency audit, mobile security review, privacy review, notification privacy review, and logging review.

## Premium product backlog

Only implement items that fit the architecture and genuinely improve the product. Prioritize in this order when choosing new work:

### Planning and task intelligence

- Natural-language task capture that converts phrases such as `Call John tomorrow at 4` into structured fields.
- Smart task grouping by Today, Next, Overdue, Priority, Favorite, and category.
- Intelligent next-action suggestions based on due dates and workload.
- Quick reschedule/snooze presets from task cards and notifications.
- Bulk select/edit/complete/delete/archive.
- Task templates for repeated workflows.
- Routines that create or manage a group of recurring tasks.
- Subtask/checklist improvements with progress indicators.
- Archived tasks and restore.
- Safer undo for destructive and bulk operations.

### Calendar and planning

- Month/week/day calendar modes.
- Clear Today indicator and overdue visibility.
- Drag-to-reschedule with confirmation/undo where appropriate.
- Workload density and capacity cues.
- Planning view that makes upcoming commitments easy to scan.

### Focus and insights

- Focus sessions with pause/resume and current-task emphasis.
- Optional task-linked focus sessions.
- Focus history and useful productivity trends.
- Completion and workload insights without manipulative streak mechanics.
- Daily/weekly review surfaces.

### Notifications and device experience

- Notification actions for complete and snooze.
- Reliable recurring reminder lifecycle.
- Deep links from notifications into the correct task.
- Lock-screen/privacy-conscious notification text.
- App widgets where platform support and project scope justify them.
- Background/restart recovery for scheduled reminders.

### Search and organization

- Global search.
- Fast filters and sorting.
- Saved/smart views.
- Categories/lists and tags.
- Favorites.
- Recently completed and archived views.

### Account and settings

- Strong onboarding and permission education.
- Appearance/theme controls.
- Default reminder and task behavior.
- Week-start preference.
- Time/date preferences.
- Account/session management.
- Account deletion flow.
- Email verification decision/implementation.
- Privacy controls and transparent sync status.

## Non-negotiable quality rules

- Do not sacrifice reliability for visual polish.
- Do not break offline-first behavior.
- Do not weaken server authorization or sync conflict guarantees.
- Do not store tokens in plaintext app preferences or logs.
- Do not create reminder behavior that depends on the app being open.
- Preserve explicit timezone semantics for scheduled work.
- New features require tests when they touch critical behavior.
- Prefer small, reviewable commits with descriptive messages.
- Fetch the current file/blob before updating an existing GitHub file; never reuse a stale SHA.
- Do not force-push or rewrite backend history.
- Keep generated/build artifacts out of Git.

## Definition of "best"

The app should feel fast, calm, predictable, polished, and trustworthy. A user should be able to capture a task in seconds, schedule it confidently, work offline, receive the right reminder at the right local time, act directly from the notification, recover from mistakes, and trust that the same state appears correctly across devices.

The final release bar is not "many features." It is a product where the important paths feel exceptionally finished and where edge cases are deliberately tested.
