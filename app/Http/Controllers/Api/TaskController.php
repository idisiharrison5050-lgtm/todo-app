<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Task;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TaskController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:read'), 403);
        return response()->json($request->user()->tasks()->latest('updated_at')->paginate(100));
    }

    public function deleted(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:read'), 403);
        return response()->json(DB::table('deleted_tasks')->where('user_id', $request->user()->id)->orderBy('deleted_at')->paginate(100, ['client_id', 'deleted_at', 'sync_version']));
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $validated = $request->validate([
            'client_id' => ['required', 'string', 'max:64'],
            'title' => ['required', 'string', 'max:200', 'not_regex:/^\s*$/'],
            'completed' => ['sometimes', 'boolean'],
            'payload' => ['required', 'array', 'max:50'],
            'client_updated_at' => ['nullable', 'date'],
            'sync_version' => ['nullable', 'integer', 'min:1'],
        ]);
        $incomingVersion = $validated['sync_version'] ?? null;
        $clientUpdatedAt = $validated['client_updated_at'] ?? $this->clientUpdatedAt($validated['payload']);
        $deleted = DB::table('deleted_tasks')->where('user_id', $request->user()->id)->where('client_id', $validated['client_id'])->first();
        if ($deleted) {
            if ($incomingVersion !== null && $deleted->sync_version !== null && $incomingVersion <= (int) $deleted->sync_version) return response()->json(['message' => 'This task was deleted on the server.', 'deleted' => true, 'sync_version' => (int) $deleted->sync_version], 409);
            $incoming = $clientUpdatedAt ? Carbon::parse($clientUpdatedAt) : now();
            if ($incoming->lessThanOrEqualTo(Carbon::parse($deleted->deleted_at))) return response()->json(['message' => 'This task was deleted on the server.', 'deleted' => true, 'sync_version' => $deleted->sync_version ? (int) $deleted->sync_version : null], 409);
            DB::table('deleted_tasks')->where('id', $deleted->id)->delete();
        }
        $existing = $request->user()->tasks()->where('client_id', $validated['client_id'])->first();
        if ($existing && $incomingVersion !== null && $incomingVersion < (int) $existing->sync_version) return response()->json(['message' => 'Server has a newer version of this task.', 'task' => $this->canonicalTask($existing->fresh())], 409);
        if ($existing && $incomingVersion === null && $existing->client_updated_at && $clientUpdatedAt && $existing->client_updated_at->greaterThan(Carbon::parse($clientUpdatedAt))) return response()->json(['message' => 'Server has a newer version of this task.', 'task' => $this->canonicalTask($existing->fresh())], 409);
        $nextVersion = $existing ? ((int) $existing->sync_version + 1) : 1;
        $task = $request->user()->tasks()->updateOrCreate(['client_id' => $validated['client_id']], ['title' => trim($validated['title']), 'completed' => $validated['completed'] ?? false, 'payload' => $validated['payload'], 'client_updated_at' => $clientUpdatedAt ? Carbon::parse($clientUpdatedAt) : now(), 'sync_version' => $nextVersion]);
        return response()->json(['task' => $this->canonicalTask($task->fresh())], $existing ? 200 : 201);
    }

    public function update(Request $request, Task $task): JsonResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $validated = $request->validate(['title' => ['sometimes', 'required', 'string', 'max:200', 'not_regex:/^\s*$/'], 'completed' => ['sometimes', 'boolean'], 'payload' => ['sometimes', 'required', 'array', 'max:50'], 'client_updated_at' => ['nullable', 'date'], 'sync_version' => ['nullable', 'integer', 'min:1']]);
        $incomingVersion = $validated['sync_version'] ?? null;
        $clientUpdatedAt = $validated['client_updated_at'] ?? (isset($validated['payload']) ? $this->clientUpdatedAt($validated['payload']) : null);
        if ($incomingVersion !== null && $incomingVersion < (int) $task->sync_version) return response()->json(['message' => 'Server has a newer version of this task.', 'task' => $this->canonicalTask($task->fresh())], 409);
        if ($incomingVersion === null && $clientUpdatedAt && $task->client_updated_at && $task->client_updated_at->greaterThan(Carbon::parse($clientUpdatedAt))) return response()->json(['message' => 'Server has a newer version of this task.', 'task' => $this->canonicalTask($task->fresh())], 409);
        if (isset($validated['title'])) $validated['title'] = trim($validated['title']);
        if ($clientUpdatedAt) $validated['client_updated_at'] = Carbon::parse($clientUpdatedAt);
        unset($validated['sync_version']);
        if (isset($validated['payload'])) {
            $validated['payload']['title'] = $validated['title'] ?? $validated['payload']['title'] ?? $task->title;
            $validated['payload']['isCompleted'] = $validated['completed'] ?? $validated['payload']['isCompleted'] ?? $task->completed;
        }
        $validated['sync_version'] = (int) $task->sync_version + 1;
        $task->update($validated);
        return response()->json(['task' => $this->canonicalTask($task->fresh())]);
    }

    public function destroy(Request $request, Task $task): JsonResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $this->tombstone($request, $task->client_id, $task);
        return response()->json(['message' => 'Task deleted.']);
    }

    public function destroyByClientId(Request $request, string $clientId): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $task = $request->user()->tasks()->where('client_id', $clientId)->first();
        if ($task) $this->tombstone($request, $task->client_id, $task);
        else if (!DB::table('deleted_tasks')->where('user_id', $request->user()->id)->where('client_id', $clientId)->exists()) DB::table('deleted_tasks')->insert(['user_id' => $request->user()->id, 'client_id' => $clientId, 'deleted_at' => now(), 'sync_version' => 1]);
        return response()->json(['message' => 'Task deleted.']);
    }

    private function tombstone(Request $request, string $clientId, ?Task $task = null): void
    {
        DB::transaction(function () use ($request, $clientId, $task) {
            $syncVersion = $task ? ((int) $task->sync_version + 1) : 1;
            DB::table('deleted_tasks')->updateOrInsert(['user_id' => $request->user()->id, 'client_id' => $clientId], ['deleted_at' => now(), 'sync_version' => $syncVersion]);
            if ($task) $task->delete();
        });
    }

    private function clientUpdatedAt(array $payload): ?Carbon
    {
        $value = $payload['updatedAt'] ?? null;
        if (!is_string($value) || $value === '') return null;
        try { return Carbon::parse($value); } catch (\Throwable $e) { return null; }
    }

    private function canonicalTask(Task $task): array
    {
        $payload = is_array($task->payload) ? $task->payload : [];
        $payload['id'] = $task->client_id;
        $payload['title'] = $task->title;
        $payload['isCompleted'] = $task->completed;
        $payload['updatedAt'] = $task->updated_at?->toISOString();
        $payload['syncVersion'] = (int) $task->sync_version;
        if (!isset($payload['createdAt']) && $task->created_at) $payload['createdAt'] = $task->created_at->toISOString();
        return ['id' => $task->id, 'client_id' => $task->client_id, 'title' => $task->title, 'completed' => $task->completed, 'payload' => $payload, 'sync_version' => (int) $task->sync_version, 'client_updated_at' => $task->client_updated_at?->toISOString(), 'updated_at' => $task->updated_at?->toISOString(), 'created_at' => $task->created_at?->toISOString()];
    }
}
