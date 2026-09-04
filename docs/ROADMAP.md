# Roadmap

## Stage 0 — Plan
- [x] Define product vision
- [x] Define MVP boundaries
- [x] Define architecture
- [x] Define security baseline
- [x] Define testing strategy
- [x] Review plan through implementation

## Stage 1 — Backend Foundation
- [x] Confirm Laravel/PHP baseline
- [x] Database migrations for users/tasks/tokens
- [x] API v1 foundation
- [x] Authentication/error validation foundation
- [x] Login rate limiting baseline
- [x] CI with Flutter analyze/test and Laravel test suite
- [x] Health endpoint
- [ ] Production observability/monitoring

## Stage 2 — Identity
- [x] Registration
- [x] Login
- [x] Logout/revocation
- [x] Password reset API and notification flow
- [x] Secure mobile credential storage
- [x] Basic authorization isolation tests
- [ ] Account deletion flow
- [ ] Email verification decision/implementation

## Stage 3 — Tasks
- [x] Task model
- [x] Task CRUD API
- [x] User ownership enforcement
- [x] Today/upcoming views
- [x] Basic search/filter UI
- [x] Backend task API tests

## Stage 4 — Reminders
- [x] Reminder model
- [x] One-time scheduling contract
- [x] Daily/weekly/selected-weekday recurrence contract
- [x] Explicit timezone storage
- [x] Snooze configuration storage
- [x] Reminder CRUD API
- [x] Reminder authorization tests
- [x] Recurrence/date unit tests
- [x] Mobile notification scheduling implementation
- [x] Notification action/background handling implementation
- [ ] Cold-start notification navigation verification on physical devices
- [ ] DST/timezone integration matrix

## Stage 5 — Flutter Foundation
- [x] iOS project
- [x] Android project
- [x] Mobile architecture documented
- [x] Secure storage implementation
- [x] Local database implementation
- [x] API client implementation
- [x] Local notification implementation
- [x] Platform notification requirements documented
- [ ] Production-grade release configuration/signing

## Stage 6 — Premium MVP UX
- [x] Core design/theme foundation
- [ ] Final onboarding/permission UX review
- [x] Today screen
- [x] Add/edit task flow
- [x] Reminder flow
- [x] Upcoming/calendar views
- [x] Search/filter
- [ ] Final settings/account UX review
- [ ] Accessibility pass
- [ ] Final responsive/screen-size review

## Stage 7 — Offline + Sync
- [x] Local task cache/database
- [x] Pending mutation queue
- [x] Idempotency keys
- [x] Server sync versions
- [x] Conflict handling for stale writes
- [x] Deletion tombstones/versioning
- [x] Account-scoped local sync metadata
- [x] Retry-safe mutation flow
- [ ] Two-device conflict integration tests
- [ ] Physical offline/reconnect verification

## Stage 8 — Hardening
- [ ] OWASP-style API review
- [ ] Dependency vulnerability audit
- [ ] Mobile security review
- [ ] Privacy review
- [ ] Notification privacy review
- [ ] Logging review
- [x] Idempotency concurrency race protection

## Stage 9 — QA
- [x] Backend unit/API tests for implemented critical paths
- [x] Flutter unit/domain tests for implemented critical paths
- [ ] Broader widget/component tests
- [ ] Integration tests for critical user journeys
- [ ] Physical iOS testing
- [ ] Physical Android testing
- [ ] Offline testing
- [ ] Accessibility testing
- [ ] Timezone/DST testing

## Stage 10 — Private Beta
- [ ] Production-like backend
- [ ] HTTPS
- [ ] Secrets management
- [ ] Backups
- [ ] Monitoring/error tracking
- [ ] iOS internal/TestFlight path
- [ ] Android internal testing
- [ ] Real-world reminder reliability test

## Stage 11 — Public Release Preparation
- [ ] Store privacy disclosures
- [ ] Apple review checklist
- [ ] Google Play policy checklist
- [ ] Store assets
- [ ] Release signing
- [ ] Rollback plan
- [ ] Final security/privacy review

## Current position
The backend authentication, task, reminder, synchronization, deletion-tombstone, and idempotency foundations are implemented and covered by a green CI pipeline. The Flutter client has secure token storage, local persistence, API synchronization, offline mutation handling, timezone-aware reminder scheduling, snooze actions, and core task/reminder screens.

The next work is **hardening and verification**, not adding random features: finish sync conflict edge cases, complete timezone/DST and notification lifecycle tests, perform the security/dependency/privacy review, then validate the complete app on a physical Android device before private beta.
