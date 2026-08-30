# Roadmap

## Stage 0 — Plan
- [x] Define product vision
- [x] Define MVP boundaries
- [x] Define architecture
- [x] Define security baseline
- [x] Define testing strategy
- [ ] Review and approve plan

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
- [ ] Authorization tests

## Stage 3 — Tasks
- [x] Task model
- [x] Task CRUD API
- [x] User ownership enforcement
- [ ] Today/upcoming queries
- [ ] Filters/search
- [ ] Backend tests

## Stage 4 — Reminders
- [ ] Reminder model
- [ ] One-time scheduling
- [ ] Recurrence rules
- [ ] Timezone handling
- [ ] Snooze
- [ ] Notification lifecycle
- [ ] Reminder tests

## Stage 5 — Flutter
- [ ] iOS project
- [ ] Android project
- [ ] App architecture
- [ ] Secure storage
- [ ] Local database
- [ ] API client
- [ ] Notification integration

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

**Current position:** Stages 1–3 foundation is substantially implemented. The next engineering milestone is the reminder domain and scheduling design, followed by the Flutter client.
