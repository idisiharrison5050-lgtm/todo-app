<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Task;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:read'), 403);
        return response()->json($request->user()->tasks()->latest('updated_at')->paginate(100));
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

        $clientUpdatedAt = $this->clientUpdatedAt($validated['payload']);
        $existing = $request->user()->tasks()->where('client_id', $validated['client_id'])->first();

        if ($existing && $existing->client_updated_at && $clientUpdatedAt && $existing->client_updated_at->greaterThan($clientUpdatedAt)) {
            return response()->json(['message' => 'Server has a newer version of this task.', 'task' => $existing], 409);
        }

        $task = $request->user()->tasks()->updateOrCreate(
            ['client_id' => $validated['client_id']],
            [
                'title' => trim($validated['title']),
                'completed' => $validated['completed'] ?? false,
                'payload' => $validated['payload'],
                'client_updated_at' => $clientUpdatedAt ?? now(),
            ]
        );
        return response()->json(['task' => $task->fresh()], $existing ? 200 : 201);
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
        $clientUpdatedAt = isset($validated['payload']) ? $this->clientUpdatedAt($validated['payload']) : null;
        if ($clientUpdatedAt && $task->client_updated_at && $task->client_updated_at->greaterThan($clientUpdatedAt)) {
            return response()->json(['message' => 'Server has a newer version of this task.', 'task' => $task->fresh()], 409);
        }
        if (isset($validated['title'])) $validated['title'] = trim($validated['title']);
        if ($clientUpdatedAt) $validated['client_updated_at'] = $clientUpdatedAt;
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

    private function clientUpdatedAt(array $payload): ?Carbon
    {
        $value = $payload['updatedAt'] ?? null;
        if (!is_string($value) || $value === '') return null;
        try { return Carbon::parse($value); } catch (\Throwable $e) { return null; }
    }
}
