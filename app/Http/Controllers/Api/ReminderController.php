<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reminder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReminderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:read'), 403);
        $reminders = $request->user()->reminders()->with('task')->latest()->paginate(50);
        return response()->json($reminders);
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $validated = $request->validate([
            'task_id' => ['required', 'integer', 'exists:tasks,id'],
            'timezone' => ['required', 'timezone', 'max:64'],
            'type' => ['required', 'in:once,daily,weekly,weekdays'],
            'starts_at' => ['required', 'date'],
            'hour' => ['nullable', 'integer', 'between:0,23'],
            'minute' => ['nullable', 'integer', 'between:0,59'],
            'weekdays' => ['nullable', 'array', 'min:1', 'max:7'],
            'weekdays.*' => ['integer', 'between:1,7', 'distinct'],
            'snooze_minutes' => ['nullable', 'integer', 'between:1,1440'],
            'enabled' => ['nullable', 'boolean'],
        ]);
        $task = $request->user()->tasks()->findOrFail($validated['task_id']);
        $reminder = $request->user()->reminders()->create([
            'task_id' => $task->id,
            'timezone' => $validated['timezone'],
            'type' => $validated['type'],
            'starts_at' => $validated['starts_at'],
            'hour' => $validated['hour'] ?? null,
            'minute' => $validated['minute'] ?? null,
            'weekdays' => $validated['weekdays'] ?? null,
            'snooze_minutes' => $validated['snooze_minutes'] ?? 10,
            'enabled' => $validated['enabled'] ?? true,
        ]);
        return response()->json($reminder->load('task'), 201);
    }

    public function update(Request $request, Reminder $reminder): JsonResponse
    {
        abort_unless($reminder->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $validated = $request->validate([
            'timezone' => ['sometimes', 'timezone', 'max:64'],
            'type' => ['sometimes', 'in:once,daily,weekly,weekdays'],
            'starts_at' => ['sometimes', 'date'],
            'hour' => ['nullable', 'integer', 'between:0,23'],
            'minute' => ['nullable', 'integer', 'between:0,59'],
            'weekdays' => ['nullable', 'array', 'min:1', 'max:7'],
            'weekdays.*' => ['integer', 'between:1,7', 'distinct'],
            'snooze_minutes' => ['sometimes', 'integer', 'between:1,1440'],
            'enabled' => ['sometimes', 'boolean'],
        ]);
        $reminder->update($validated);
        return response()->json($reminder->fresh()->load('task'));
    }

    public function destroy(Request $request, Reminder $reminder): JsonResponse
    {
        abort_unless($reminder->user_id === $request->user()->id, 404);
        abort_unless($request->user()->tokenCan('tasks:write'), 403);
        $reminder->delete();
        return response()->json(['message' => 'Reminder deleted.']);
    }
}
