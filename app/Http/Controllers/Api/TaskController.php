<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:read'), 403);

        $tasks = $request->user()->tasks()->latest('updated_at')->paginate(100);

        return response()->json($tasks);
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:write'), 403);

        $validated = $request->validate([
            'client_id' => ['required', 'string', 'max:64'],
            'title' => ['required', 'string', 'max:200'],
            'completed' => ['sometimes', 'boolean'],
            'payload' => ['required', 'array'],
        ]);

        $task = $request->user()->tasks()->updateOrCreate(
            ['client_id' => $validated['client_id']],
            [
                'title' => trim($validated['title']),
                'completed' => $validated['completed'] ?? false,
                'payload' => $validated['payload'],
            ]
        );

        return response()->json(['task' => $task], 201);
    }

    public function update(Request $request, Task $task): JsonResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:200'],
            'completed' => ['sometimes', 'boolean'],
            'payload' => ['sometimes', 'required', 'array'],
        ]);

        if (isset($validated['title'])) {
            $validated['title'] = trim($validated['title']);
        }

        $task->update($validated);

        return response()->json(['task' => $task->fresh()]);
    }

    public function destroy(Request $request, Task $task): JsonResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);

        $task->delete();

        return response()->json(['message' => 'Task deleted.']);
    }
}
