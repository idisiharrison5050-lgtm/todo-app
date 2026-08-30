<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Today — Todo</title>
    <style>
        :root { color-scheme: dark; --bg:#080b12; --panel:#101620; --panel2:#151c28; --line:#253044; --muted:#8d99ab; --text:#f6f8fb; --accent:#7c5cff; --danger:#fb7185; }
        * { box-sizing:border-box; }
        body { margin:0; min-height:100vh; font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; background:radial-gradient(circle at 15% 0%,#1b1633 0,transparent 34%),var(--bg); color:var(--text); }
        .shell { width:min(1080px,100%); margin:auto; padding:30px 20px 60px; }
        .top { display:flex; justify-content:space-between; align-items:center; gap:20px; margin-bottom:34px; }
        .brand { font-weight:800; letter-spacing:-.03em; font-size:22px; }
        .brand span { color:var(--accent); }
        .user { display:flex; align-items:center; gap:14px; color:var(--muted); font-size:14px; }
        .logout { background:transparent; color:#c5ccda; border:1px solid var(--line); padding:9px 13px; border-radius:10px; cursor:pointer; }
        .hero { margin-bottom:26px; }
        .eyebrow { color:#a99bff; font-size:12px; font-weight:800; letter-spacing:.12em; text-transform:uppercase; }
        h1 { font-size:clamp(38px,7vw,64px); letter-spacing:-.055em; line-height:1; margin:9px 0 10px; }
        .sub { margin:0; color:var(--muted); font-size:16px; }
        .layout { display:grid; grid-template-columns:1fr 300px; gap:20px; }
        .card { background:rgba(16,22,32,.88); border:1px solid var(--line); border-radius:22px; overflow:hidden; box-shadow:0 25px 80px rgba(0,0,0,.25); }
        .add { display:flex; gap:10px; padding:16px; border-bottom:1px solid var(--line); }
        input { width:100%; min-width:0; padding:15px 16px; border-radius:13px; border:1px solid #334056; background:#0b1018; color:#fff; outline:none; font:inherit; }
        input:focus { border-color:#8f80ff; box-shadow:0 0 0 4px rgba(124,92,255,.12); }
        button { font:inherit; }
        .add button { border:0; border-radius:13px; padding:0 20px; background:var(--accent); color:#fff; font-weight:800; cursor:pointer; }
        .toolbar { display:flex; justify-content:space-between; align-items:center; padding:14px 18px; color:var(--muted); font-size:13px; border-bottom:1px solid var(--line); }
        .clear { background:none; border:0; color:#aeb8c9; cursor:pointer; }
        .clear:hover { color:#fff; }
        ul { list-style:none; padding:0; margin:0; }
        li { display:flex; align-items:center; gap:13px; padding:16px 18px; border-bottom:1px solid #1c2533; }
        li:last-child { border:0; }
        .check { width:22px; height:22px; padding:0; border:2px solid #536077; border-radius:50%; background:transparent; color:#fff; cursor:pointer; display:grid; place-items:center; }
        .check.done { background:var(--accent); border-color:var(--accent); }
        .task { flex:1; min-width:0; overflow-wrap:anywhere; line-height:1.4; }
        li.completed .task { color:#687489; text-decoration:line-through; }
        .delete { border:0; background:transparent; color:#667187; cursor:pointer; font-size:22px; padding:3px 7px; }
        .delete:hover { color:var(--danger); }
        .empty { padding:55px 20px; text-align:center; color:#687489; }
        .side { padding:22px; }
        .side h2 { font-size:15px; margin:0 0 18px; }
        .stat { display:flex; justify-content:space-between; padding:14px 0; border-bottom:1px solid #202a3a; color:var(--muted); }
        .stat strong { color:#fff; }
        .error { padding:12px 18px; color:#fda4af; background:rgba(244,63,94,.07); border-bottom:1px solid rgba(244,63,94,.15); font-size:13px; }
        @media (max-width:800px) { .layout{grid-template-columns:1fr;} .side{display:none;} }
        @media (max-width:560px) { .shell{padding:22px 12px 45px;} .top{margin-bottom:28px;} .user>span{display:none;} .add{flex-direction:column;} .add button{min-height:48px;} h1{font-size:45px;} }
    </style>
</head>
<body>
<div class="shell">
    <header class="top">
        <div class="brand">todo<span>.</span></div>
        <div class="user"><span>{{ auth()->user()->name }}</span><form action="{{ route('logout') }}" method="POST">@csrf<button class="logout" type="submit">Log out</button></form></div>
    </header>

    <section class="hero">
        <div class="eyebrow">Your day</div>
        <h1>Today.</h1>
        <p class="sub">Capture what matters. We'll build the reminder layer next.</p>
    </section>

    <div class="layout">
        <section class="card">
            <form class="add" action="{{ route('tasks.store') }}" method="POST">
                @csrf
                <input name="title" type="text" maxlength="200" placeholder="What needs to be done?" autocomplete="off" required autofocus>
                <button type="submit">Add task</button>
            </form>
            @if ($errors->any()) <div class="error">{{ $errors->first() }}</div> @endif
            <div class="toolbar">
                <span>{{ $tasks->where('completed', false)->count() }} remaining</span>
                <form action="{{ route('tasks.clear-completed') }}" method="POST">@csrf @method('DELETE')<button class="clear" type="submit">Clear completed</button></form>
            </div>
            @if ($tasks->isEmpty())
                <div class="empty">Nothing here yet.<br>Start with one small thing.</div>
            @else
                <ul>
                    @foreach ($tasks as $task)
                        <li class="{{ $task->completed ? 'completed' : '' }}">
                            <form action="{{ route('tasks.toggle', $task) }}" method="POST">@csrf @method('PATCH')<button class="check {{ $task->completed ? 'done' : '' }}" type="submit" aria-label="Mark task {{ $task->completed ? 'active' : 'complete' }}">{{ $task->completed ? '✓' : '' }}</button></form>
                            <div class="task">{{ $task->title }}</div>
                            <form action="{{ route('tasks.destroy', $task) }}" method="POST">@csrf @method('DELETE')<button class="delete" type="submit" aria-label="Delete task">×</button></form>
                        </li>
                    @endforeach
                </ul>
            @endif
        </section>

        <aside class="card side">
            <h2>Overview</h2>
            <div class="stat"><span>Total</span><strong>{{ $tasks->count() }}</strong></div>
            <div class="stat"><span>Active</span><strong>{{ $tasks->where('completed', false)->count() }}</strong></div>
            <div class="stat"><span>Completed</span><strong>{{ $tasks->where('completed', true)->count() }}</strong></div>
        </aside>
    </div>
</div>
</body>
</html>
