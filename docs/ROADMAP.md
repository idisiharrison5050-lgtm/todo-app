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

## Stage 12 — Premium Product Completion

These are product-quality goals, not a license to add random features. Implement them only after the reliability gates above are stable.

### Task intelligence and organization
- [ ] Natural-language task capture
- [ ] Smart task grouping and smart views
- [ ] Intelligent workload-aware suggestions
- [ ] Quick reschedule/snooze actions
- [ ] Bulk task operations
- [ ] Task templates
- [ ] Routines
- [ ] Subtask/checklist progress improvements
- [ ] Archive and restore
- [ ] Robust undo flows

### Planning
- [ ] Month/week/day calendar modes
- [ ] Drag-to-reschedule with undo
- [ ] Workload/capacity cues
- [ ] Better upcoming planning view

### Focus and insights
- [ ] Real focus sessions with pause/resume
- [ ] Task-linked focus sessions
- [ ] Focus history
- [ ] Useful productivity insights
- [ ] Daily/weekly review surfaces

### Device experience
- [ ] Notification complete/snooze actions
- [ ] Notification deep links
- [ ] Cold-start/background recovery verification
- [ ] Privacy-conscious notification content
- [ ] Widgets where justified

### Account and polish
- [ ] Final onboarding and permission education
- [ ] Appearance/settings completion
- [ ] Account/session management
- [ ] Account deletion
- [ ] Email verification decision
- [ ] Accessibility completion
- [ ] Responsive/screen-size completion
- [ ] Premium motion/haptics/gesture polish

## Current position

The foundation is substantially implemented. The immediate objective is to finish reliability and verification while raising the client to a genuinely premium product bar.

**Execution order:**
1. Stabilize and type-check the latest Flutter UI changes.
2. Harden task completion/error handling and quick actions.
3. Finish Home/Today, Calendar, Focus, Search/Organization, and Settings UX.
4. Complete notification lifecycle and timezone/DST verification.
5. Complete two-device sync conflict and offline/reconnect verification.
6. Run security, dependency, privacy, and logging reviews.
7. Complete accessibility and responsive QA.
8. Validate on physical Android and iOS devices.
9. Only then move into the premium differentiator backlog and private beta/release preparation.

For the durable handoff of product intent, architecture, priorities, and engineering rules, see `docs/AI_CONTINUATION.md`.
