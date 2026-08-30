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

        $response = $this->postJson('/api/v1/reminders', [
            'task_id' => $task->id,
            'timezone' => 'Africa/Lagos',
            'type' => 'daily',
            'starts_at' => now('Africa/Lagos')->addHour()->toIso8601String(),
            'hour' => 14,
            'minute' => 0,
            'snooze_minutes' => 10,
        ]);

        $response->assertCreated()->assertJsonPath('data.task_id', $task->id);
        $this->assertDatabaseHas('reminders', ['task_id' => $task->id, 'user_id' => $user->id]);
    }

    public function test_user_cannot_attach_a_reminder_to_another_users_task(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $task = Task::create(['user_id' => $other->id, 'title' => 'Private task', 'completed' => false]);
        Sanctum::actingAs($user, ['tasks:write']);

        $response = $this->postJson('/api/v1/reminders', [
            'task_id' => $task->id,
            'timezone' => 'Africa/Lagos',
            'type' => 'once',
            'starts_at' => now('Africa/Lagos')->addHour()->toIso8601String(),
        ]);

        $response->assertNotFound();
        $this->assertDatabaseCount('reminders', 0);
    }

    public function test_user_cannot_modify_another_users_reminder(): void
    {
        $owner = User::factory()->create();
        $attacker = User::factory()->create();
        $task = Task::create(['user_id' => $owner->id, 'title' => 'Private task', 'completed' => false]);
        $reminder = Reminder::create([
            'user_id' => $owner->id,
            'task_id' => $task->id,
            'timezone' => 'Africa/Lagos',
            'type' => 'once',
            'starts_at' => now('Africa/Lagos')->addHour(),
            'snooze_minutes' => 10,
            'enabled' => true,
        ]);
        Sanctum::actingAs($attacker, ['tasks:write']);

        $this->patchJson('/api/v1/reminders/'.$reminder->id, ['enabled' => false])->assertNotFound();
        $this->deleteJson('/api/v1/reminders/'.$reminder->id)->assertNotFound();
    }
}
