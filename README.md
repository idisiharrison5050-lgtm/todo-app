# Todo & Reminder App

A cross-platform task and reminder product being built with a Laravel 13 backend and a Flutter client for iOS and Android.

## Current foundation

- Laravel 13 / PHP 8.3+
- Blade web client
- Eloquent persistence
- Per-user task ownership
- Secure browser session authentication
- Laravel Sanctum mobile API authentication
- Versioned `/api/v1` API
- Token abilities for task read/write operations
- CSRF protection for web forms
- Server-side validation
- SQLite for local development
- Reminder domain and timezone-aware scheduling contract
- Flutter 3.47.2 local development project under `C:\src\todo_mobile`

## Product direction

The MVP is an installable iOS/Android task and reminder app with dependable local notifications, recurring reminders, offline operation, synchronization, and a polished mobile-first experience. The Laravel backend is the synchronization/security boundary; the mobile client handles UI, local storage, and device notification scheduling.

Read the engineering plan before adding major features:

- `docs/PROJECT_PLAN.md` — master product and engineering plan
- `docs/ARCHITECTURE.md` — system architecture and boundaries
- `docs/MVP.md` — MVP scope and acceptance criteria
- `docs/SECURITY.md` — security and privacy baseline
- `docs/DEVELOPMENT.md` — engineering workflow
- `docs/TESTING.md` — test strategy
- `docs/ROADMAP.md` — phased implementation roadmap
- `docs/PLATFORM_NOTIFICATIONS.md` — iOS/Android notification rules

## Local Laravel setup

Requirements: PHP 8.3+, Composer, and the PHP SQLite extension.

```bash
composer install
cp .env.example .env
php artisan key:generate
mkdir -p database
touch database/database.sqlite
php artisan migrate
php artisan serve
```

Then open `http://127.0.0.1:8000`.

## Flutter development

The mobile client is currently developed locally in `C:\src\todo_mobile` using Flutter 3.47.2.

```powershell
cd C:\src\todo_mobile
flutter pub get
flutter analyze
flutter devices
```

The Android toolchain is configured and SDK licenses are accepted. Visual Studio is intentionally not required because Windows desktop is not an MVP target.

The local Flutter project is connected to this GitHub repository as its `origin`. Before pushing, review whether a file belongs in the backend repository and keep generated/build artifacts out of Git.

## Mobile API

The mobile client authenticates through Laravel Sanctum using bearer tokens. Tokens must be stored only in OS-backed secure storage on the Flutter client.

### Register

`POST /api/v1/auth/register`

```json
{
  "name": "Example User",
  "email": "user@example.com",
  "password": "at-least-8-characters",
  "password_confirmation": "at-least-8-characters",
  "device_name": "Example iPhone"
}
```

### Login

`POST /api/v1/auth/login`

```json
{
  "email": "user@example.com",
  "password": "at-least-8-characters",
  "device_name": "Example iPhone"
}
```

The response contains a bearer token. Never log or commit that token.

### Authenticated requests

Send:

```text
Authorization: Bearer <token>
Accept: application/json
```

Task endpoints:

- `GET /api/v1/tasks`
- `POST /api/v1/tasks`
- `PATCH /api/v1/tasks/{task}`
- `DELETE /api/v1/tasks/{task}`
- `GET /api/v1/me`
- `POST /api/v1/auth/logout`

Reminder endpoints are documented in the API controllers and reminder test suite and will be consumed by the Flutter reminder layer.

## Important

The current mobile project is a local working tree and is not yet committed from this machine. Do not force-push or overwrite the existing backend history. First reconcile the local Flutter project with the GitHub repository history, then create a clean baseline commit.

Production deployments must use HTTPS, production secret management, a production database, backups, monitoring, and a final security/privacy review.
