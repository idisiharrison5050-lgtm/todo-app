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
