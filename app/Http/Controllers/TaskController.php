<?php

namespace App\Http\Controllers;

use App\Models\Task;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TaskController extends Controller
{
    public function index(Request $request): View
    {
        $tasks = $request->user()->tasks()->latest()->get();

        return view('tasks.index', [
            'tasks' => $tasks,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:200'],
        ]);

        $request->user()->tasks()->create([
            'title' => trim($validated['title']),
            'completed' => false,
        ]);

        return redirect()->route('tasks.index');
    }

    public function toggle(Request $request, Task $task): RedirectResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);

        $task->update([
            'completed' => ! $task->completed,
        ]);

        return redirect()->route('tasks.index');
    }

    public function destroy(Request $request, Task $task): RedirectResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);

        $task->delete();

        return redirect()->route('tasks.index');
    }

    public function clearCompleted(Request $request): RedirectResponse
    {
        $request->user()->tasks()->where('completed', true)->delete();

        return redirect()->route('tasks.index');
    }
}
