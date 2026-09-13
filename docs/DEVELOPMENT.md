# Development Workflow

## Working order

1. Read `docs/PROJECT_PLAN.md` before starting a major feature.
2. Check the current repository state.
3. Define acceptance criteria.
4. Design data/API/UI behavior.
5. Implement the smallest complete vertical slice.
6. Add automated tests.
7. Perform security/accessibility review.
8. Update documentation.
9. Commit with a focused message.

## Feature slices

Prefer completing features end-to-end rather than building large disconnected layers. For example, a reminder slice should include database representation, API behavior, mobile scheduling, UI, error handling, and tests before moving on.

## Environment

Development, staging, and production must have separate configuration and credentials. `.env` files containing secrets must never be committed.

## Database

Schema changes must use migrations. Do not edit production data manually as part of normal feature development. Destructive migrations require an explicit migration/rollback plan.

## API contracts

Document meaningful API changes. Avoid breaking clients without versioning or a migration strategy.

## Mobile releases

Keep debug/development credentials and release signing credentials separate. Never commit signing certificates, provisioning profiles containing secrets, keystores, passwords, or service-account keys.

### Android release signing

The Android release build does not use the debug keystore. For a signed release, create `mobile/android/key.properties` locally with:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=path/to/your/upload-keystore.jks
```

Place the keystore at the path referenced by `storeFile`. `key.properties` and keystore files are ignored by Git. Keep backups of the keystore and passwords in a secure password manager or secret-management system.

If no valid `key.properties` is present, the release variant is intentionally left unsigned rather than silently falling back to the debug key. Configure signing before distributing an Android release.

Android cleartext HTTP is enabled only for the debug variant so a physical device can connect to a local development server. Release builds disable cleartext traffic and must use HTTPS.

## Code quality

- Prefer clear names over clever abstractions.
- Keep business rules out of UI widgets.
- Keep authorization on the server.
- Make date/time behavior explicit.
- Handle failures intentionally.
- Avoid unnecessary dependencies.

## Definition of done

A feature is not complete until implementation, security, tests, error states, accessibility considerations, and documentation are complete enough for its scope.

## MVP discipline

Do not add calendar integrations, AI, social features, subscriptions, location intelligence, or other deferred functionality while core task/reminder reliability remains incomplete.
