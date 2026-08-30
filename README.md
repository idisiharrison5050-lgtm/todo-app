# Todo & Reminder App

A cross-platform task and reminder product being built with a Laravel 13 backend and a future Flutter client for iOS and Android.

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

## Product direction

The MVP is not only a todo website. The target product is an installable iOS/Android task and reminder app with dependable local notifications, recurring reminders, offline operation, synchronization, and a polished mobile-first experience.

Read the engineering plan before adding major features:

- `docs/PROJECT_PLAN.md` — master product and engineering plan
- `docs/ARCHITECTURE.md` — system architecture and boundaries
- `docs/MVP.md` — MVP scope and acceptance criteria
- `docs/SECURITY.md` — security and privacy baseline
- `docs/DEVELOPMENT.md` — engineering workflow
- `docs/TESTING.md` — test strategy
- `docs/ROADMAP.md` — phased implementation roadmap

## Local setup

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

## Mobile API

The mobile client will authenticate through Laravel Sanctum using bearer tokens. Tokens should be stored only in OS-backed secure storage on the eventual Flutter client.

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

## Important

The API is a foundation for the mobile application. Local notification scheduling, offline storage, sync conflict handling, reminder recurrence, and the Flutter client are deliberately being built as separate phases. Do not treat the current API as the finished MVP.

Production deployments must use HTTPS, production secret management, a production database, backups, monitoring, and a final security/privacy review.
