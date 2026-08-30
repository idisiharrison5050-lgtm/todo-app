<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create account — Todo App</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 24px; font-family: Inter, system-ui, sans-serif; background: #0f172a; color: #f8fafc; }
        .card { width: 100%; max-width: 430px; padding: 32px; border: 1px solid #334155; border-radius: 20px; background: #111827; box-shadow: 0 24px 70px rgba(0,0,0,.35); }
        h1 { margin: 0 0 8px; font-size: 32px; }
        p { color: #94a3b8; margin: 0 0 26px; }
        label { display: block; margin: 16px 0 7px; font-size: 14px; font-weight: 700; }
        input { width: 100%; padding: 13px 14px; border: 1px solid #475569; border-radius: 10px; background: #0f172a; color: #fff; font-size: 16px; outline: none; }
        input:focus { border-color: #60a5fa; }
        button { width: 100%; margin-top: 22px; padding: 13px; border: 0; border-radius: 10px; background: #2563eb; color: #fff; font-weight: 700; cursor: pointer; }
        .errors { margin-top: 14px; color: #fca5a5; font-size: 13px; }
        .switch { margin-top: 22px; text-align: center; font-size: 14px; }
        a { color: #93c5fd; }
    </style>
</head>
<body>
<main class="card">
    <h1>Create account</h1>
    <p>Your tasks will be private to your account.</p>
    <form action="{{ route('register') }}" method="POST">
        @csrf
        <label for="name">Name</label>
        <input id="name" name="name" type="text" value="{{ old('name') }}" autocomplete="name" required autofocus>
        <label for="email">Email</label>
        <input id="email" name="email" type="email" value="{{ old('email') }}" autocomplete="email" required>
        <label for="password">Password</label>
        <input id="password" name="password" type="password" autocomplete="new-password" minlength="8" required>
        <label for="password_confirmation">Confirm password</label>
        <input id="password_confirmation" name="password_confirmation" type="password" autocomplete="new-password" minlength="8" required>
        @if ($errors->any())
            <div class="errors">{{ $errors->first() }}</div>
        @endif
        <button type="submit">Create account</button>
    </form>
    <div class="switch">Already have an account? <a href="{{ route('login') }}">Sign in</a></div>
</main>
</body>
</html>
