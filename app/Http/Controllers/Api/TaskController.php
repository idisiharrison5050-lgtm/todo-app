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
        $user = $request->user();

        $result = DB::transaction(function () use ($validated, $incomingVersion, $clientUpdatedAt, $user) {
            $deleted = DB::table('deleted_tasks')
                ->where('user_id', $user->id)
                ->where('client_id', $validated['client_id'])
                ->lockForUpdate()
                ->first();

            if ($deleted) {
                if ($incomingVersion !== null && $deleted->sync_version !== null && $incomingVersion <= (int) $deleted->sync_version) {
                    return ['response' => response()->json([
                        'message' => 'This task was deleted on the server.',
                        'deleted' => true,
                        'sync_version' => (int) $deleted->sync_version,
                    ], 409)];
                }

                $incoming = $clientUpdatedAt ? Carbon::parse($clientUpdatedAt) : now();
                if ($incoming->lessThanOrEqualTo(Carbon::parse($deleted->deleted_at))) {
                    return ['response' => response()->json([
                        'message' => 'This task was deleted on the server.',
                        'deleted' => true,
                        'sync_version' => $deleted->sync_version !== null ? (int) $deleted->sync_version : null,
                    ], 409)];
                }

                DB::table('deleted_tasks')->where('id', $deleted->id)->delete();
            }

            // Lock and re-read the task inside the same transaction. This is the
            // compare-and-apply boundary: concurrent writers cannot both validate
            // against the same old server version and then overwrite each other.
            $existing = $user->tasks()
                ->where('client_id', $validated['client_id'])
                ->lockForUpdate()
                ->first();

            if ($existing && $incomingVersion !== null && $incomingVersion < (int) $existing->sync_version) {
                return ['response' => response()->json([
                    'message' => 'Server has a newer version of this task.',
                    'task' => $this->canonicalTask($existing),
                ], 409)];
            }

            if ($existing && $incomingVersion === null && $clientUpdatedAt && $existing->client_updated_at && $existing->client_updated_at->greaterThan(Carbon::parse($clientUpdatedAt))) {
                return ['response' => response()->json([
                    'message' => 'Server has a newer version of this task.',
                    'task' => $this->canonicalTask($existing),
                ], 409)];
            }

            $nextVersion = $existing ? ((int) $existing->sync_version + 1) : 1;
            $attributes = [
                'title' => trim($validated['title']),
                'completed' => $validated['completed'] ?? false,
                'payload' => $validated['payload'],
                'client_updated_at' => $clientUpdatedAt ? Carbon::parse($clientUpdatedAt) : now(),
                'sync_version' => $nextVersion,
            ];

            if ($existing) {
                $existing->update($attributes);
                $task = $existing->fresh();
            } else {
                $task = $user->tasks()->create(array_merge(['client_id' => $validated['client_id']], $attributes));
            }

            return [
                'status' => $existing ? 200 : 201,
                'task' => $this->canonicalTask($task),
            ];
        });

        if (isset($result['response'])) return $result['response'];
        return response()->json(['task' => $result['task']], $result['status']);
    }

    public function update(Request $request, Task $task): JsonResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:200', 'not_regex:/^\s*$/'],
            'completed' => ['sometimes', 'boolean'],
            'payload' => ['sometimes', 'required', 'array', 'max:50'],
            'client_updated_at' => ['nullable', 'date'],
            'sync_version' => ['nullable', 'integer', 'min:1'],
        ]);

        $incomingVersion = $validated['sync_version'] ?? null;
        $clientUpdatedAt = $validated['client_updated_at'] ?? (isset($validated['payload']) ? $this->clientUpdatedAt($validated['payload']) : null);
        $user = $request->user();

        $result = DB::transaction(function () use ($validated, $incomingVersion, $clientUpdatedAt, $user, $task) {
            // Route-model binding gave us the identity, but the row must be locked
            // and re-read before comparing versions so a concurrent delete/update
            // cannot invalidate the conflict decision.
            $current = $user->tasks()->whereKey($task->id)->lockForUpdate()->first();
            if (! $current) abort(404);

            if ($incomingVersion !== null && $incomingVersion < (int) $current->sync_version) {
                return ['response' => response()->json([
                    'message' => 'Server has a newer version of this task.',
                    'task' => $this->canonicalTask($current),
                ], 409)];
            }

            if ($incomingVersion === null && $clientUpdatedAt && $current->client_updated_at && $current->client_updated_at->greaterThan(Carbon::parse($clientUpdatedAt))) {
                return ['response' => response()->json([
                    'message' => 'Server has a newer version of this task.',
                    'task' => $this->canonicalTask($current),
                ], 409)];
            }

            if (isset($validated['title'])) $validated['title'] = trim($validated['title']);
            if ($clientUpdatedAt) $validated['client_updated_at'] = Carbon::parse($clientUpdatedAt);
            unset($validated['sync_version']);

            if (isset($validated['payload'])) {
                $validated['payload']['title'] = $validated['title'] ?? $validated['payload']['title'] ?? $current->title;
                $validated['payload']['isCompleted'] = $validated['completed'] ?? $validated['payload']['isCompleted'] ?? $current->completed;
            }

            $validated['sync_version'] = (int) $current->sync_version + 1;
            $current->update($validated);

            return ['task' => $this->canonicalTask($current->fresh())];
        });

        if (isset($result['response'])) return $result['response'];
        return response()->json(['task' => $result['task']]);
    }

    public function destroy(Request $request, Task $task): JsonResponse
    {
        abort_unless($task->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);

        $result = DB::transaction(function () use ($request, $task) {
            $current = $request->user()->tasks()->whereKey($task->id)->lockForUpdate()->first();
            if (! $current) return false;
            $this->tombstoneLocked($request->user()->id, $current->client_id, $current);
            return true;
        });

        if (! $result) abort(404);
        return response()->json(['message' => 'Task deleted.']);
    }

    public function destroyByClientId(Request $request, string $clientId): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $incomingVersion = $request->query('sync_version');
        if ($incomingVersion !== null && (!is_numeric($incomingVersion) || (int) $incomingVersion < 1)) return response()->json(['message' => 'Invalid sync version.'], 422);

        $result = DB::transaction(function () use ($request, $clientId, $incomingVersion) {
            $task = $request->user()->tasks()->where('client_id', $clientId)->lockForUpdate()->first();
            if ($task) {
                if ($incomingVersion !== null && (int) $incomingVersion < (int) $task->sync_version) {
                    return ['response' => response()->json([
                        'message' => 'Server has a newer version of this task.',
                        'task' => $this->canonicalTask($task),
                    ], 409)];
                }
                $this->tombstoneLocked($request->user()->id, $task->client_id, $task);
                return [];
            }

            $deleted = DB::table('deleted_tasks')
                ->where('user_id', $request->user()->id)
                ->where('client_id', $clientId)
                ->lockForUpdate()
                ->first();

            if (! $deleted) {
                DB::table('deleted_tasks')->insert([
                    'user_id' => $request->user()->id,
                    'client_id' => $clientId,
                    'deleted_at' => now(),
                    'sync_version' => 1,
                ]);
            }

            return [];
        });

        if (isset($result['response'])) return $result['response'];
        return response()->json(['message' => 'Task deleted.']);
    }

    private function tombstoneLocked(int $userId, string $clientId, Task $task): void
    {
        DB::table('deleted_tasks')->updateOrInsert(
            ['user_id' => $userId, 'client_id' => $clientId],
            ['deleted_at' => now(), 'sync_version' => (int) $task->sync_version + 1]
        );
        $task->delete();
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
