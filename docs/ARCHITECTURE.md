# Architecture — Todo & Reminder MVP

## Objective

Create a cross-platform application with a Flutter mobile client for iOS/Android and a Laravel backend providing authenticated APIs and synchronized persistence. The web client may consume the same backend, but mobile reliability is the primary MVP concern.

## System boundaries

### Client is responsible for
- Rendering UI.
- Local task cache.
- Offline mutation queue.
- Local notification scheduling.
- Secure credential storage.
- Permission UX.
- Presenting server validation/errors.

### Server is responsible for
- Authentication and authorization.
- User ownership.
- Canonical task/reminder records.
- Validation.
- Rate limiting.
- Synchronization/versioning.
- Device registration metadata.
- Operational auditing.

### Database

Relational database. Every user-owned entity must have a clear ownership relationship and appropriate indexes.

## API principles

- Version APIs from the beginning, e.g. `/api/v1`.
- JSON request/response contracts.
- Consistent validation errors.
- Authentication required for private resources.
- Authorization on every resource mutation/read path.
- Idempotency for retried client mutations.
- Pagination for potentially unbounded collections.
- Server-controlled timestamps and ownership.
- Never expose internal database identifiers unnecessarily.

## Synchronization model

The device keeps a local representation and a queue of pending mutations. Synchronization sends operations to the server and receives canonical state/version information.

A mutation should carry a client-generated idempotency key. The server must safely recognize repeated delivery of the same operation.

Deletion requires tombstone/version handling sufficient to prevent an offline device from resurrecting deleted data.

## Notification model

The server stores the user's reminder intent. The mobile client schedules local notifications for the next required occurrences. When a reminder changes, the client cancels stale schedules and creates the new schedule.

Do not depend on a permanently running server process to fire a phone-local reminder. Do not assume background execution is unlimited on iOS or Android.

For reminders requiring server-side push in later versions, introduce APNs/FCM only for events that genuinely require remote delivery and keep secrets/service credentials server-side.

## Time and timezone model

Store absolute instants in UTC where appropriate and retain the user's intended IANA timezone for recurring schedules. Recurring rules must be interpreted in the intended local timezone rather than by blindly adding UTC durations.

Test daylight-saving transitions even though the primary target may not observe DST; users can travel and device timezone settings can change.

## Security boundaries

The Flutter application is untrusted. Any authorization decision made only in Flutter is not a security control.

The Laravel API is the security boundary. Every task/reminder query and mutation must be scoped to the authenticated user.

## Data minimization

Store only information required by the product. Avoid analytics SDKs and third-party services in the MVP unless their necessity, privacy impact, and security posture are reviewed.

## Observability

Logs must support diagnosis without recording passwords, tokens, notification secrets, or unnecessary private task content. Production error responses must not expose stack traces or implementation details.
