# Security Baseline

Security is part of every phase, not a final cleanup task.

## Authentication
- Use framework-supported password hashing.
- Never store plaintext passwords.
- Rate-limit login, registration, password reset, and verification endpoints.
- Store mobile credentials only in iOS Keychain / Android Keystore-backed secure storage.
- Never place tokens in logs, analytics events, URLs, screenshots, or source control.

## Authorization
- Treat all mobile/web input as untrusted.
- Scope every private query to the authenticated user.
- Use explicit token abilities and ownership checks for resource mutations.
- Add automated tests proving cross-user access is impossible.

## API
- HTTPS in every production environment.
- Strict request validation and reasonable payload limits.
- CORS restricted to known origins in production.
- Secure headers where applicable.
- Consistent non-sensitive error responses.
- Rate limiting and abuse controls are applied to authentication and task/reminder API operations.
- Synchronization uses a server-controlled task version; clients must provide their last known version for conflict-sensitive writes.
- Deletion tombstones carry a server-side version so stale offline copies cannot resurrect deleted tasks.
- Retry-safe/idempotent mutation identifiers remain a release-gate requirement and must be completed before public release.

## Mobile
- Secure storage for credentials.
- No embedded backend/admin secrets.
- Minimize permissions.
- Explain notification permission requests in context.
- Do not expose sensitive task content in notifications by default where lock-screen privacy is a concern.
- Handle app lifecycle, process death, background notification actions, and cold-start notification taps safely.
- Do not treat jailbreak/root detection as authorization.

## Data protection
- Encrypt data in transit.
- Use encrypted storage mechanisms supplied by the operating system for secrets.
- Database access uses least-privilege service credentials.
- Backups must be protected and access-controlled.
- Production secrets belong in a secret manager/environment, never Git.

## Privacy
- Minimize collected data.
- Avoid unnecessary third-party SDKs in MVP.
- Document data retention/deletion behavior.
- Provide account/data deletion before public release.
- Prepare platform privacy/data-safety disclosures before store submission.

## Dependency and supply-chain security
- Pin or constrain dependencies appropriately.
- Run dependency vulnerability checks in CI.
- Review new third-party packages before adoption.
- Keep build/signing credentials outside the repository.

## Threat scenarios to test
1. User A attempts to access User B's task by changing an ID.
2. Expired/revoked credentials are reused.
3. Login/password reset is brute-forced.
4. A mutation request is replayed.
5. Offline deletion races with an older device update.
6. Malformed reminder schedules are submitted.
7. Client sends another user's ownership identifier.
8. Notification data is visible on a locked phone.
9. Logs accidentally contain credentials or private data.
10. A compromised client attempts to bypass authorization.

## Release rule

No critical or high-severity unresolved security issue is acceptable for an MVP private beta. Public store release requires a separate final security/privacy review.
