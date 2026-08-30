# Flutter Code Architecture

Planned structure:

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    errors/
    network/
    storage/
    permissions/
    notifications/
    time/
  features/
    auth/
      data/
      domain/
      presentation/
    tasks/
      data/
      domain/
      presentation/
    reminders/
      data/
      domain/
      presentation/
  shared/
    widgets/
    models/
```

## Rules

- UI widgets do not own business rules.
- Domain logic is testable without Flutter bindings.
- API DTOs are not used directly as UI state.
- Secure credentials are isolated behind a storage abstraction.
- Notification scheduling is isolated behind a notification service.
- Local persistence is isolated behind repositories.
- Sync logic is deterministic and separately testable.
- Date/time calculations use explicit timezone-aware domain types/logic.
