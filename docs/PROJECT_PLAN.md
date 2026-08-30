# Todo & Reminder App — Master Project Plan

**Status:** Planning / MVP foundation
**Repository:** `idisiharrison5050-lgtm/todo-app`
**Product type:** Cross-platform task and reminder application
**Primary clients:** iOS, Android, Web
**Backend:** Laravel API
**Mobile:** Flutter

## 1. Product Vision

Build a polished, reliable personal task and reminder application that makes it effortless to capture what needs to be done, schedule when it should happen, and receive dependable reminders on a phone.

The MVP is intentionally narrow: tasks, reminders, recurring reminders, notifications, accounts, offline-first behavior, synchronization, and a high-quality mobile experience. The architecture must not prevent later expansion into calendars, widgets, collaboration, wearables, voice input, location reminders, and intelligent natural-language scheduling.

## 2. Engineering Principles

1. Security and privacy are requirements, not post-release work.
2. Local device behavior must remain useful when offline.
3. The server is the source of truth for synchronized user data; the device is the source of truth for immediate local notification scheduling.
4. Never trust client-provided ownership, authorization, timestamps, or identifiers.
5. Minimize collection and retention of personal data.
6. Prefer simple, boring, maintainable architecture over unnecessary complexity.
7. Accessibility, performance, and platform conventions are part of definition-of-done.
8. No production secrets, signing keys, API credentials, or real user data in Git.
9. Every feature must have acceptance criteria and tests before being considered complete.
10. Do not add features to the MVP merely because they are technically interesting.

## 3. Target MVP

### Included
- Account registration, login, logout, password reset.
- Secure authenticated API sessions/tokens appropriate to the mobile architecture.
- User-owned tasks.
- Task title and optional description.
- Task completion state.
- Due date/time.
- One-time reminders.
- Recurring reminders: daily, weekly, selected weekdays, and configurable intervals where technically reliable.
- Local phone notifications.
- Notification permission onboarding and settings.
- Snooze.
- Today / upcoming task views.
- Basic task filtering and search.
- Basic priority/category support if it does not delay core reliability.
- Offline task creation/edit/completion with later synchronization.
- Conflict-safe synchronization.
- Cross-device synchronization.
- Responsive web client for account/data access.
- Secure backend validation and authorization.
- Automated unit, feature/API, and mobile tests for critical paths.

### Explicitly deferred
- Social features.
- Shared/team tasks.
- Payments/subscriptions.
- AI task parsing.
- Location-based reminders.
- Calendar integrations.
- Wearables.
- Voice assistants.
- Complex collaboration.
- Ads/analytics that are not essential.
- Public App Store / Play Store release until release gates are satisfied.

## 4. High-Level Architecture

```text
Flutter iOS app ─┐
                 ├── HTTPS/JSON API ── Laravel ── Database
Flutter Android ─┘                       │
                                         └── Notification/device-token services

Web client ─────── HTTPS/JSON/API or Laravel web layer
```

### Responsibilities

**Flutter client**
- UI and navigation.
- Local persistence/cache.
- Local notification scheduling.
- Offline queue.
- Sync engine.
- Secure token storage using platform secure storage.
- Device permission handling.

**Laravel backend**
- Authentication/session management.
- Authorization and ownership checks.
- Task/reminder persistence.
- API validation and rate limiting.
- Synchronization protocol.
- Device registration metadata.
- Audit/security logging without sensitive payload leakage.

**Database**
- Users.
- Tasks.
- Reminder definitions/occurrences as needed by the chosen scheduling model.
- Device registrations.
- Sync metadata/version information.

## 5. Detailed Development Phases

### Phase 0 — Product and Repository Baseline
**Goal:** Establish a controlled engineering baseline before feature work.

Deliverables:
- Master project plan.
- Architecture decision record.
- MVP acceptance criteria.
- Repository structure.
- Branch/commit conventions.
- Environment strategy.
- Definition of done.
- Threat model draft.

Exit criteria:
- Team can explain the architecture and MVP boundaries.
- No secrets committed.
- Documentation matches repository state.

### Phase 1 — Architecture and Laravel Foundation
**Goal:** Establish the backend correctly.

Work:
- Confirm Laravel version and supported PHP version.
- Configure environment separation.
- Configure database and migrations.
- Establish API routing/versioning strategy.
- Add health endpoint with no sensitive information.
- Establish consistent API response/error format.
- Add request validation conventions.
- Add authorization/policy conventions.
- Configure logging and production-safe error handling.
- Configure rate limits.
- Add automated backend test framework and CI baseline.

Security:
- HTTPS-only production policy.
- Secure cookies where web sessions are used.
- CSRF protection for browser state-changing requests.
- Authentication throttling.
- No credentials in source control.
- Principle of least privilege for database/service accounts.

Exit criteria:
- Clean installation from documented steps.
- Migrations work from an empty database.
- CI passes.
- Security baseline is documented.

### Phase 2 — Identity and Account Security
**Goal:** Give each user a secure private account.

Work:
- Registration.
- Login.
- Logout/session revocation.
- Password reset.
- Email verification if required by the final product risk model.
- Session/device management where appropriate.
- Account deletion flow design.

Security:
- Strong password hashing using framework defaults.
- No plaintext passwords.
- Secure token storage on device.
- Short-lived access credentials with secure refresh/revocation strategy.
- Rate-limit authentication endpoints.
- Prevent account enumeration where practical.
- Validate all identifiers server-side.
- Authorization tests for every protected resource.

Exit criteria:
- User A cannot read or mutate User B data.
- Authentication abuse controls are tested.
- Password reset cannot be abused to take over another account.

### Phase 3 — Core Task Domain
**Goal:** Implement the reliable task model.

Data model should support:
- UUID/public identifiers where appropriate.
- owner/user relationship.
- title.
- description.
- completion state and timestamps.
- due date/time with explicit timezone semantics.
- priority.
- category if included in MVP.
- created/updated timestamps.
- soft deletion only if justified by sync requirements.

API operations:
- List tasks.
- Create task.
- Update task.
- Complete/uncomplete task.
- Delete task.
- Filter/sort/search.

Security:
- Every query scoped to authenticated owner.
- Policies for every mutation.
- Mass-assignment protection.
- Strict validation and length limits.
- Reject impossible dates/state transitions where applicable.

Exit criteria:
- Full CRUD behavior is covered by automated tests.
- Ownership isolation is proven by tests.

### Phase 4 — Reminder Domain and Scheduling Model
**Goal:** Make reminders a first-class product capability.

Reminder types:
- One-time date/time.
- Daily.
- Weekly.
- Selected weekdays.
- Interval-based reminders only where platform behavior is reliable.

Requirements:
- Explicit timezone attached to scheduled behavior.
- DST-safe scheduling rules.
- Enable/disable reminder.
- Snooze.
- Next occurrence calculation.
- Avoid duplicate notifications after retries/restarts.
- Handle edits/deletions by cancelling/rescheduling local notifications.

Important design rule:
- The backend stores reminder intent and synchronization state.
- The mobile device schedules local notifications for dependable offline behavior.
- The server must never assume a notification was displayed merely because it requested or synchronized a reminder.

Exit criteria:
- One-time reminders fire at the intended local time.
- Recurring reminders survive app restarts.
- Editing/deleting a reminder cannot leave stale notifications.
- DST/timezone behavior has explicit tests.

### Phase 5 — Flutter Mobile Foundation
**Goal:** Build a production-quality mobile shell.

Work:
- Flutter project setup for iOS and Android.
- Architecture with clear presentation/domain/data boundaries.
- Navigation.
- Theme/design system.
- Secure storage.
- API client.
- Local database/cache.
- Error/loading/empty states.
- Permission abstraction.
- Notification abstraction.

Platform requirements:
- Respect iOS Human Interface Guidelines and Apple platform permission behavior.
- Respect Android Material/platform navigation, permission, background execution, and notification behavior.
- Support dynamic text sizing where practical.
- Support screen readers and semantic labels.
- Avoid unnecessary background execution.
- Handle lifecycle changes, process death, notification taps, and cold starts.

Exit criteria:
- App launches cleanly on supported iOS and Android test devices.
- Navigation and core architecture are stable.

### Phase 6 — Next-Level MVP UX/UI
**Goal:** Make the product feel premium without adding unnecessary features.

Design direction:
- Calm, focused, minimal interface.
- Strong visual hierarchy.
- Fast task capture.
- Excellent typography and spacing.
- Subtle motion used for feedback, not decoration.
- Clear completion states.
- One-handed mobile interaction.
- Dark/light themes if feasible without compromising accessibility.

Core screens:
1. Onboarding / permissions.
2. Sign in / registration.
3. Today.
4. Upcoming.
5. Add/edit task.
6. Reminder configuration.
7. Task details.
8. Search/filter.
9. Settings.
10. Account/security.

UX rules:
- Adding a simple task should require minimal interaction.
- Reminder setup should be understandable without documentation.
- Never hide destructive actions behind ambiguous controls.
- Confirm only genuinely destructive/high-impact actions.
- Use undo where safer than confirmation.

Exit criteria:
- Critical user journeys require minimal taps.
- Accessibility review completed.
- No clipped content at supported device sizes/text scaling.

### Phase 7 — Offline-First and Synchronization
**Goal:** Make the app dependable with poor or absent connectivity.

Local state:
- Tasks cached locally.
- Pending mutations queued.
- Local reminder schedules retained.

Sync protocol:
- Each mutation gets a client operation/idempotency identifier.
- Server returns canonical resource version/timestamps.
- Sync is retryable.
- Duplicate requests are safe.
- Conflict rules are explicit.
- Deleted records are represented safely long enough to synchronize deletion.

Conflict policy for MVP:
- Prefer deterministic last-write-wins using server-assigned timestamps/versioning for ordinary edits, with special handling for completion and deletion where required.
- Never silently overwrite newer server data due to stale client state.

Exit criteria:
- Airplane-mode task creation works.
- Reconnect synchronizes without duplicate tasks.
- Two-device edits follow documented conflict rules.

### Phase 8 — Security Hardening
**Goal:** Treat the MVP as a real product, not a demo.

Backend:
- OWASP-aligned API security review.
- Input validation.
- Authorization review.
- Rate limiting.
- Secure headers.
- CORS restricted to required origins.
- Dependency vulnerability scanning.
- SQL injection protection through framework/database APIs.
- XSS-safe output handling.
- SSRF review for any future outbound integrations.
- Secure error responses.
- Sensitive-data logging review.
- Backup/restore strategy.

Mobile:
- Secure credential storage using Keychain/Keystore-backed mechanisms.
- No tokens in logs.
- No secrets in app source.
- Transport security.
- Screenshot/background privacy decisions for sensitive screens.
- Jailbreak/root detection only if justified; never as a substitute for server authorization.
- Notification content should avoid unnecessary sensitive information on lock screens.

Privacy:
- Data minimization.
- Clear privacy policy requirements before store submission.
- Account/data deletion requirements.
- Explicit notification permission handling.
- Analytics disabled by default unless required and privacy-reviewed.

Exit criteria:
- Threat model reviewed.
- Critical/high security findings resolved.
- Dependency audit completed.

### Phase 9 — Automated Testing and Quality Engineering
**Goal:** Establish confidence before deployment.

Backend tests:
- Unit tests for reminder/date logic.
- Feature/API tests.
- Authentication tests.
- Authorization/ownership tests.
- Validation tests.
- Rate-limit tests.
- Sync/idempotency tests.

Mobile tests:
- Unit tests for domain logic.
- Widget/component tests.
- Integration tests for critical flows.
- Notification scheduling tests where testable.
- Offline/online sync tests.

Manual matrix:
- Multiple iPhone screen sizes.
- Multiple Android screen sizes.
- Older supported OS versions.
- Light/dark mode.
- Large text.
- No network.
- Slow network.
- App killed/restarted.
- Device reboot.
- Notification permission denied/allowed.
- Timezone changes.
- DST transitions.

Exit criteria:
- Critical path automated tests pass.
- No known blocker defects.
- Performance and accessibility gates pass.

### Phase 10 — Production Readiness
**Goal:** Prepare for real users without publishing prematurely.

Work:
- Production environment.
- Managed database.
- TLS/HTTPS.
- Secret management.
- Backups.
- Monitoring.
- Error tracking with privacy controls.
- Rate limits.
- Database migration strategy.
- Rollback strategy.
- Disaster recovery runbook.
- Release builds.

Exit criteria:
- Production deployment is reproducible.
- Restore procedure has been tested.
- Monitoring detects major failures.

### Phase 11 — Device Beta / Internal Distribution
**Goal:** Install and use the MVP on real devices before public stores.

iOS:
- Development signing.
- Test installation.
- TestFlight preparation when appropriate.

Android:
- Debug/release signing separation.
- Internal testing APK/AAB.

Test with real daily workflows:
- Drink water.
- Start class.
- End meeting.
- Recurring reminders.
- Snooze.
- Offline task capture.
- Cross-device synchronization.

Exit criteria:
- Several days of real-world use without critical reminder failures.
- Battery/background behavior acceptable.

### Phase 12 — Store Readiness (Later, Not MVP Build Blocker)
**Goal:** Prepare public distribution after product quality is proven.

Apple:
- App Store metadata.
- Privacy disclosures.
- Permission explanations.
- Screenshots.
- App Review compliance.
- Production signing/release pipeline.

Google:
- Play Console setup.
- Data safety disclosures.
- Content/app declarations.
- Store listing.
- Release signing.
- Internal/closed/open testing progression as appropriate.

Do not submit until the release checklist is green.

## 6. Security Threat Model

Primary threats:
- Account takeover.
- Broken object-level authorization.
- Stolen mobile tokens.
- API abuse/brute force.
- Maliciously crafted task/reminder payloads.
- Cross-user data leakage through sync.
- Duplicate/replayed mutations.
- Notification privacy leakage.
- Insecure local storage.
- Dependency compromise.
- Secrets accidentally committed to Git.

Security controls must be implemented at the correct layer. Client checks are UX controls; server authorization is the security boundary.

## 7. Privacy Requirements

The MVP should collect only data needed for accounts, synchronization, tasks, reminders, notifications, and operational reliability.

Never log:
- Passwords.
- Access/refresh tokens.
- Session secrets.
- Authentication codes.
- Full private task content unless explicitly required for a controlled debugging process.

Notification previews should be configurable and should avoid exposing sensitive task content by default where platform lock-screen behavior makes that a concern.

## 8. Performance Targets

Initial goals, to be validated on representative devices:
- App cold start should feel immediate and remain responsive.
- Local task creation should not wait for network.
- Main Today screen should render from local state quickly.
- API calls should have sensible timeouts and retries.
- Sync must avoid unbounded queues or repeated duplicate operations.
- Battery use from reminders/background work must remain conservative.

## 9. Accessibility Definition of Done

- Semantic labels for controls.
- Logical focus/navigation order.
- Sufficient contrast.
- Text scaling support.
- No meaning conveyed by color alone.
- Touch targets appropriate to platform guidance.
- Screen-reader announcement for important state changes.
- Reduced-motion considerations.

## 10. Git and Delivery Discipline

- Small, coherent commits.
- Never commit secrets.
- Feature branches for substantial work.
- Pull requests for production-critical changes when practical.
- Documentation updated with architectural changes.
- Database migrations are forward-safe and reviewed.
- Do not rewrite production history.
- Keep generated/build artifacts out of Git.

## 11. Definition of Done

A feature is done only when:
- Requirements are clear.
- UI behavior is implemented.
- Backend/API behavior is implemented where required.
- Authorization is implemented and tested.
- Validation is implemented.
- Offline behavior is defined where relevant.
- Error states exist.
- Accessibility has been considered.
- Automated tests cover critical behavior.
- Documentation is updated.
- No secrets are introduced.
- The feature works on supported iOS and Android versions where applicable.

## 12. MVP Release Gate

The MVP is ready for private device beta only when all of these are true:

- [ ] Registration/login works securely.
- [ ] Users can create, edit, complete, and delete tasks.
- [ ] One-time reminders work reliably.
- [ ] Recurring reminders work reliably.
- [ ] Notification permissions are handled correctly.
- [ ] Snooze works.
- [ ] Reminders survive app restart/device restart according to platform capabilities.
- [ ] Offline task operations work.
- [ ] Sync works without duplicate data.
- [ ] User data is isolated server-side.
- [ ] Critical security tests pass.
- [ ] Accessibility review passes critical checks.
- [ ] Performance/battery behavior is acceptable.
- [ ] Automated critical-path tests pass.
- [ ] Production secrets are managed outside Git.
- [ ] Backup/restore strategy exists.
- [ ] Privacy/store documentation is prepared before public distribution.

## 13. Post-MVP Roadmap

After the MVP proves the core experience:

1. Calendar integration.
2. Natural-language task/reminder creation.
3. Widgets.
4. Location reminders.
5. Shared tasks.
6. Collaboration.
7. Wearables.
8. Voice assistant integration.
9. Advanced recurring schedules.
10. Smart planning and productivity insights.

The guiding rule remains: **make the core reminder experience exceptionally reliable before expanding the feature surface.**
