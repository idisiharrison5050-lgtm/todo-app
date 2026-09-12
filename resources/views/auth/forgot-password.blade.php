<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forgot Password — Todo App</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 24px; font-family: Inter, system-ui, sans-serif; background: #0f172a; color: #f8fafc; }
        .card { width: 100%; max-width: 430px; padding: 32px; border: 1px solid #334155; border-radius: 20px; background: #111827; box-shadow: 0 24px 70px rgba(0,0,0,.35); }
        h1 { margin: 0 0 8px; font-size: 32px; }
        p { color: #94a3b8; margin: 0 0 26px; line-height: 1.5; }
        label { display: block; margin: 16px 0 7px; font-size: 14px; font-weight: 700; }
        input { width: 100%; padding: 13px 14px; border: 1px solid #475569; border-radius: 10px; background: #0f172a; color: #fff; font-size: 16px; outline: none; }
        input:focus { border-color: #60a5fa; }
        button { width: 100%; margin-top: 22px; padding: 13px; border: 0; border-radius: 10px; background: #2563eb; color: #fff; font-weight: 700; cursor: pointer; }
        .error { margin-top: 14px; color: #fca5a5; font-size: 13px; }
        .status { margin-top: 14px; color: #86efac; font-size: 13px; }
        .back { margin-top: 22px; text-align: center; font-size: 14px; }
        a { color: #93c5fd; }
    </style>
</head>
<body>
<main class="card">
    <h1>Forgot your password?</h1>
    <p>Enter your email and, if an account exists, we'll send you a secure password reset link.</p>
    <form action="{{ route('password.email') }}" method="POST">
        @csrf
        <label for="email">Email</label>
        <input id="email" name="email" type="email" value="{{ old('email') }}" autocomplete="email" required autofocus>
        @if ($errors->any()) <div class="error">{{ $errors->first() }}</div> @endif
        @if (session('status')) <div class="status">{{ session('status') }}</div> @endif
        <button type="submit">Send reset link</button>
    </form>
    <div class="back"><a href="{{ route('login') }}">Back to sign in</a></div>
</main>
</body>
</html>
