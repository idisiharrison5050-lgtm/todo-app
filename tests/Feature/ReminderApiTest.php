<?php

namespace Tests\Feature;

use App\Models\Reminder;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReminderApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_a_reminder_for_their_task(): void
    {
        $user = User::factory()->create();
        $task = Task::create(['user_id' => $user->id, 'title' => 'Drink water', 'completed' => false]);
        Sanctum::actingAs($user, ['tasks:write']);
        $response = $this->postJson('/api/v1/reminders', ['task_id' => $task->id, 'timezone' => 'Africa/Lagos', 'type' => 'daily', 'starts_at' => now('Africa/Lagos')->addHour()->toIso8601String(), 'hour' => 14, 'minute' => 0, 'snooze_minutes' => 10]);
        $response->assertCreated()->assertJsonPath('task_id', $task->id);
        $this->assertDatabaseHas('reminders', ['task_id' => $task->id, 'user_id' => $user->id]);
    }

    public function test_user_cannot_attach_a_reminder_to_another_users_task(): void
    {
        $user = User::factory()->create(); $other = User::factory()->create();
        $task = Task::create(['user_id' => $other->id, 'title' => 'Private task', 'completed' => false]);
        Sanctum::actingAs($user, ['tasks:write']);
        $this->postJson('/api/v1/reminders', ['task_id' => $task->id, 'timezone' => 'Africa/Lagos', 'type' => 'once', 'starts_at' => now('Africa/Lagos')->addHour()->toIso8601String()])->assertNotFound();
        $this->assertDatabaseCount('reminders', 0);
    }

    public function test_user_cannot_modify_another_users_reminder(): void
    {
        $owner = User::factory()->create(); $attacker = User::factory()->create();
        $task = Task::create(['user_id' => $owner->id, 'title' => 'Private task', 'completed' => false]);
        $reminder = Reminder::create(['user_id' => $owner->id, 'task_id' => $task->id, 'timezone' => 'Africa/Lagos', 'type' => 'once', 'starts_at' => now('Africa/Lagos')->addHour(), 'snooze_minutes' => 10, 'enabled' => true]);
        Sanctum::actingAs($attacker, ['tasks:write']);
        $this->patchJson('/api/v1/reminders/'.$reminder->id, ['enabled' => false])->assertNotFound();
        $this->deleteJson('/api/v1/reminders/'.$reminder->id)->assertNotFound();
    }

    public function test_reminder_requires_the_task_write_ability(): void
    {
        $user = User::factory()->create();
        $task = Task::create(['user_id' => $user->id, 'title' => 'Ability check', 'completed' => false]);
        Sanctum::actingAs($user, ['tasks:read']);
        $this->postJson('/api/v1/reminders', ['task_id' => $task->id, 'timezone' => 'Africa/Lagos', 'type' => 'once', 'starts_at' => now('Africa/Lagos')->addHour()->toIso8601String()])->assertForbidden();
    }

    public function test_successful_reminder_creation_is_replayed_for_the_same_idempotency_key(): void
    {
        $user = User::factory()->create();
        $task = Task::create(['user_id' => $user->id, 'title' => 'Idempotent reminder', 'completed' => false]);
        Sanctum::actingAs($user, ['tasks:write']);
        $payload = ['task_id' => $task->id, 'timezone' => 'Africa/Lagos', 'type' => 'daily', 'starts_at' => now('Africa/Lagos')->addHour()->toIso8601String(), 'hour' => 14, 'minute' => 0, 'snooze_minutes' => 10, 'enabled' => true];
        $this->withHeader('Idempotency-Key', 'reminder-operation-001')->postJson('/api/v1/reminders', $payload)->assertCreated();
        $this->withHeader('Idempotency-Key', 'reminder-operation-001')->postJson('/api/v1/reminders', $payload)->assertCreated();
        $this->assertDatabaseCount('reminders', 1);
        $this->assertDatabaseCount('sync_operations', 1);
    }

    public function test_reminder_idempotency_key_cannot_be_reused_for_a_different_mutation(): void
    {
        $user = User::factory()->create();
        $task = Task::create(['user_id' => $user->id, 'title' => 'Reminder task', 'completed' => false]);
        Sanctum::actingAs($user, ['tasks:write']);
        $base = ['task_id' => $task->id, 'timezone' => 'Africa/Lagos', 'type' => 'daily', 'starts_at' => now('Africa/Lagos')->addHour()->toIso8601String(), 'hour' => 14, 'minute' => 0];
        $this->withHeader('Idempotency-Key', 'reminder-operation-002')->postJson('/api/v1/reminders', $base)->assertCreated();
        $changed = array_merge($base, ['hour' => 15]);
        $this->withHeader('Idempotency-Key', 'reminder-operation-002')->postJson('/api/v1/reminders', $changed)->assertStatus(409);
        $this->assertDatabaseCount('reminders', 1);
    }
}
