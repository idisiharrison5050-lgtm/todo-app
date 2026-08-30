# Todo App

A simple full-stack Todo application built with Laravel 13, Blade, Eloquent, and SQLite.

## Features

- Add tasks
- Mark tasks complete or active
- Delete tasks
- Clear completed tasks
- Persistent database storage
- CSRF protection and server-side validation
- Responsive dark interface

## Run locally

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

Laravel applications should be served from the `public` directory. Laravel uses Composer for its framework dependencies and migrations to create the application's database tables.
