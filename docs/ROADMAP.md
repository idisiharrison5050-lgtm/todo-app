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
- [ ] CI/security checks
- [ ] Health/observability baseline

## Stage 2 — Identity
- [x] Registration
- [x] Login
- [x] Logout/revocation
- [ ] Password reset
- [ ] Secure mobile credential storage
- [x] Basic authorization isolation tests

## Stage 3 — Tasks
- [x] Task model
- [x] Task CRUD API
- [x] User ownership enforcement
- [ ] Today/upcoming queries
- [ ] Filters/search
- [ ] Backend task test suite

## Stage 4 — Reminders
- [x] Reminder model
- [x] One-time scheduling contract
- [x] Daily/weekly/selected-weekday recurrence contract
- [x] Explicit timezone storage
- [x] Snooze configuration storage
- [x] Reminder CRUD API
- [x] Reminder authorization tests
- [x] Recurrence unit tests
- [ ] Mobile notification scheduling
- [ ] Notification lifecycle handling
- [ ] DST/timezone integration tests

## Stage 5 — Flutter
- [ ] iOS project
- [ ] Android project
- [x] Mobile architecture documented
- [ ] Secure storage implementation
- [ ] Local database implementation
- [ ] API client implementation
- [ ] Local notification implementation
- [x] Platform notification requirements documented

## Stage 6 — Premium MVP UX
- [ ] Design system
- [ ] Onboarding
- [ ] Today screen
- [ ] Add task flow
- [ ] Reminder flow
- [ ] Upcoming view
- [ ] Search/filter
- [ ] Settings
- [ ] Accessibility pass

## Stage 7 — Offline + Sync
- [ ] Local cache
- [ ] Mutation queue
- [ ] Idempotency
- [ ] Conflict handling
- [ ] Deletion tombstones/versioning
- [ ] Cross-device tests

## Stage 8 — Hardening
- [ ] OWASP-style API review
- [ ] Dependency audit
- [ ] Mobile security review
- [ ] Privacy review
- [ ] Notification privacy review
- [ ] Logging review

## Stage 9 — QA
- [ ] Unit tests
- [ ] API tests
- [ ] Mobile tests
- [ ] Integration tests
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
- [ ] Monitoring
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
- [ ] Final security review

**Current position:** Backend reminder domain and API are implemented. Mobile architecture and platform notification requirements are documented. The next implementation step is generating the Flutter project and building its secure API/storage/notification foundations.
