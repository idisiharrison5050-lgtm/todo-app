<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Todos</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: linear-gradient(135deg, #111827, #1f2937 55%, #0f172a); color: #f8fafc; display: flex; justify-content: center; padding: 48px 18px; }
        .app { width: 100%; max-width: 720px; }
        .header { margin-bottom: 24px; }
        .eyebrow { color: #93c5fd; font-size: 13px; font-weight: 700; letter-spacing: .12em; text-transform: uppercase; }
        h1 { margin: 7px 0 8px; font-size: clamp(32px, 7vw, 52px); line-height: 1; }
        .subtitle { margin: 0; color: #94a3b8; }
        .card { background: rgba(15, 23, 42, .88); border: 1px solid #334155; border-radius: 20px; box-shadow: 0 24px 70px rgba(0,0,0,.3); overflow: hidden; }
        .add { display: flex; gap: 10px; padding: 18px; border-bottom: 1px solid #334155; }
        input { flex: 1; min-width: 0; padding: 14px 16px; border-radius: 12px; border: 1px solid #475569; background: #0f172a; color: white; outline: none; font-size: 16px; }
        input:focus { border-color: #60a5fa; box-shadow: 0 0 0 3px rgba(96,165,250,.12); }
        button { border: 0; cursor: pointer; font: inherit; }
        .add button { padding: 0 20px; border-radius: 12px; background: #2563eb; color: white; font-weight: 700; }
        .toolbar { display: flex; justify-content: space-between; gap: 12px; padding: 14px 18px; border-bottom: 1px solid #334155; }
        .clear { color: #94a3b8; background: transparent; font-size: 13px; }
        .clear:hover { color: #fca5a5; }
        ul { list-style: none; padding: 0; margin: 0; }
        li { display: flex; align-items: center; gap: 12px; padding: 15px 18px; border-bottom: 1px solid #1e293b; }
        li:last-child { border-bottom: 0; }
        .check { width: 21px; height: 21px; border-radius: 50%; border: 2px solid #64748b; flex: 0 0 auto; background: transparent; }
        .check.done { background: #2563eb; border-color: #2563eb; color: white; }
        .task { flex: 1; min-width: 0; overflow-wrap: anywhere; }
        li.completed .task { color: #64748b; text-decoration: line-through; }
        .delete { color: #64748b; background: transparent; font-size: 20px; padding: 3px 6px; }
        .delete:hover { color: #f87171; }
        .empty { text-align: center; padding: 46px 20px; color: #64748b; }
        .footer { display: flex; justify-content: space-between; color: #64748b; font-size: 13px; padding: 16px 18px; }
        .error { margin: 0 18px 14px; color: #fca5a5; font-size: 13px; }
        @media (max-width: 520px) { body { padding: 28px 12px; } .add { flex-direction: column; } .add button { min-height: 46px; } }
    </style>
</head>
<body>
<main class="app">
    <header class="header">
        <div class="eyebrow">Laravel Todo</div>
        <h1>My Todos</h1>
        <p class="subtitle">Your tasks are now stored in the database.</p>
    </header>

    <section class="card">
        <form class="add" action="{{ route('tasks.store') }}" method="POST">
            @csrf
            <input name="title" type="text" maxlength="200" placeholder="What needs to be done?" autocomplete="off" required autofocus>
            <button type="submit">Add task</button>
        </form>

        @if ($errors->any())
            <div class="error">{{ $errors->first('title') }}</div>
        @endif

        <div class="toolbar">
            <span>{{ $tasks->where('completed', false)->count() }} {{ $tasks->where('completed', false)->count() === 1 ? 'task' : 'tasks' }} left</span>
            <form action="{{ route('tasks.clear-completed') }}" method="POST">
                @csrf
                @method('DELETE')
                <button class="clear" type="submit">Clear completed</button>
            </form>
        </div>

        @if ($tasks->isEmpty())
            <div class="empty">No tasks here yet. Add your first one above.</div>
        @else
            <ul>
                @foreach ($tasks as $task)
                    <li class="{{ $task->completed ? 'completed' : '' }}">
                        <form action="{{ route('tasks.toggle', $task) }}" method="POST">
                            @csrf
                            @method('PATCH')
                            <button class="check {{ $task->completed ? 'done' : '' }}" type="submit" aria-label="Toggle task">{{ $task->completed ? '✓' : '' }}</button>
                        </form>
                        <div class="task">{{ $task->title }}</div>
                        <form action="{{ route('tasks.destroy', $task) }}" method="POST">
                            @csrf
                            @method('DELETE')
                            <button class="delete" type="submit" aria-label="Delete task">×</button>
                        </form>
                    </li>
                @endforeach
            </ul>
        @endif

        <div class="footer"><span>{{ $tasks->count() }} total {{ $tasks->count() === 1 ? 'task' : 'tasks' }}</span><span>Saved with Laravel</span></div>
    </section>
</main>
</body>
</html>
