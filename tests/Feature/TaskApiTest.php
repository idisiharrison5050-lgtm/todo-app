<?php

namespace Tests\Feature;

use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TaskApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_and_list_their_tasks(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['tasks:read', 'tasks:write']);
        $response = $this->postJson('/api/v1/tasks', ['client_id' => 'task-001', 'title' => '  Buy groceries  ', 'completed' => false, 'payload' => ['id' => 'task-001', 'title' => 'Buy groceries', 'isCompleted' => false, 'updatedAt' => now()->toIso8601String()], 'client_updated_at' => now()->toIso8601String()]);
        $response->assertCreated()->assertJsonPath('task.client_id', 'task-001')->assertJsonPath('task.title', 'Buy groceries')->assertJsonPath('task.payload.id', 'task-001')->assertJsonPath('task.sync_version', 1);
        $this->getJson('/api/v1/tasks')->assertOk()->assertJsonPath('data.0.client_id', 'task-001');
    }

    public function test_user_cannot_read_another_users_tasks(): void
    {
        $owner = User::factory()->create(); $other = User::factory()->create();
        Task::create(['user_id' => $owner->id, 'client_id' => 'private-task', 'title' => 'Private task', 'completed' => false, 'payload' => ['id' => 'private-task', 'title' => 'Private task']]);
        Sanctum::actingAs($other, ['tasks:read']);
        $this->getJson('/api/v1/tasks')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_user_cannot_update_or_delete_another_users_task(): void
    {
        $owner = User::factory()->create(); $attacker = User::factory()->create();
        $task = Task::create(['user_id' => $owner->id, 'client_id' => 'private-task', 'title' => 'Private task', 'completed' => false, 'payload' => ['id' => 'private-task', 'title' => 'Private task']]);
        Sanctum::actingAs($attacker, ['tasks:write']);
        $this->patchJson('/api/v1/tasks/'.$task->id, ['title' => 'Hacked', 'client_updated_at' => now()->toIso8601String()])->assertNotFound();
        $this->deleteJson('/api/v1/tasks/'.$task->id)->assertNotFound();
        $this->assertDatabaseHas('tasks', ['id' => $task->id, 'title' => 'Private task']);
    }

    public function test_user_cannot_delete_another_users_task_by_client_id(): void
    {
        $owner = User::factory()->create(); $attacker = User::factory()->create();
        $task = Task::create(['user_id' => $owner->id, 'client_id' => 'shared-client-id', 'title' => 'Owner task', 'completed' => false, 'payload' => ['id' => 'shared-client-id', 'title' => 'Owner task'], 'sync_version' => 3]);
        Sanctum::actingAs($attacker, ['tasks:write']);

        $this->deleteJson('/api/v1/tasks/by-client/shared-client-id')->assertOk();

        $this->assertDatabaseHas('tasks', ['id' => $task->id, 'user_id' => $owner->id, 'client_id' => 'shared-client-id', 'title' => 'Owner task']);
        $this->assertDatabaseMissing('deleted_tasks', ['user_id' => $owner->id, 'client_id' => 'shared-client-id']);
        $this->assertDatabaseHas('deleted_tasks', ['user_id' => $attacker->id, 'client_id' => 'shared-client-id']);
    }

    public function test_stale_update_returns_the_canonical_server_task(): void
    {
        $user = User::factory()->create(); $serverTime = Carbon::parse('2026-09-04T08:00:00Z');
        $task = Task::create(['user_id' => $user->id, 'client_id' => 'conflict-task', 'title' => 'Server version', 'completed' => true, 'payload' => ['id' => 'conflict-task', 'title' => 'Server version', 'isCompleted' => true], 'client_updated_at' => $serverTime]);
        $task->created_at = $serverTime->copy()->subHour(); $task->updated_at = $serverTime; $task->saveQuietly();
        Sanctum::actingAs($user, ['tasks:write']);
        $this->postJson('/api/v1/tasks', ['client_id' => 'conflict-task', 'title' => 'Older local version', 'completed' => false, 'payload' => ['id' => 'conflict-task', 'title' => 'Older local version', 'isCompleted' => false], 'client_updated_at' => $serverTime->copy()->subMinute()->toIso8601String()])->assertStatus(409)->assertJsonPath('task.client_id', 'conflict-task')->assertJsonPath('task.title', 'Server version')->assertJsonPath('task.completed', true);
    }

    public function test_server_sync_version_rejects_stale_client_even_when_clock_is_newer(): void
    {
        $user = User::factory()->create();
        Task::create(['user_id' => $user->id, 'client_id' => 'version-task', 'title' => 'New server data', 'completed' => false, 'payload' => ['id' => 'version-task', 'title' => 'New server data'], 'sync_version' => 4]);
        Sanctum::actingAs($user, ['tasks:write']);
        $this->postJson('/api/v1/tasks', ['client_id' => 'version-task', 'title' => 'Stale client', 'completed' => false, 'payload' => ['id' => 'version-task', 'title' => 'Stale client', 'updatedAt' => now()->addYear()->toIso8601String()], 'sync_version' => 3])->assertStatus(409)->assertJsonPath('task.sync_version', 4)->assertJsonPath('task.title', 'New server data');
    }

    public function test_equal_sync_version_is_only_accepted_once_and_next_replay_is_rejected(): void
    {
        $user = User::factory()->create();
        $time = Carbon::parse('2026-09-04T09:00:00Z');
        Task::create(['user_id' => $user->id, 'client_id' => 'cas-task', 'title' => 'Base', 'completed' => false, 'payload' => ['id' => 'cas-task', 'title' => 'Base'], 'client_updated_at' => $time, 'sync_version' => 1]);
        Sanctum::actingAs($user, ['tasks:write']);

        $this->postJson('/api/v1/tasks', ['client_id' => 'cas-task', 'title' => 'First writer', 'completed' => false, 'payload' => ['id' => 'cas-task', 'title' => 'First writer'], 'client_updated_at' => $time->copy()->addMinute()->toIso8601String(), 'sync_version' => 1])->assertOk()->assertJsonPath('task.sync_version', 2)->assertJsonPath('task.title', 'First writer');

        $this->postJson('/api/v1/tasks', ['client_id' => 'cas-task', 'title' => 'Second stale writer', 'completed' => false, 'payload' => ['id' => 'cas-task', 'title' => 'Second stale writer'], 'client_updated_at' => $time->copy()->addMinutes(2)->toIso8601String(), 'sync_version' => 1])->assertStatus(409)->assertJsonPath('task.sync_version', 2)->assertJsonPath('task.title', 'First writer');
    }

    public function test_update_rechecks_the_server_version_inside_the_transaction(): void
    {
        $user = User::factory()->create();
        $time = Carbon::parse('2026-09-04T10:00:00Z');
        $task = Task::create(['user_id' => $user->id, 'client_id' => 'update-cas-task', 'title' => 'Base', 'completed' => false, 'payload' => ['id' => 'update-cas-task', 'title' => 'Base'], 'client_updated_at' => $time, 'sync_version' => 2]);
        Sanctum::actingAs($user, ['tasks:write']);

        $this->patchJson('/api/v1/tasks/'.$task->id, ['title' => 'First update', 'payload' => ['id' => 'update-cas-task', 'title' => 'First update'], 'client_updated_at' => $time->copy()->addMinute()->toIso8601String(), 'sync_version' => 2])->assertOk()->assertJsonPath('task.sync_version', 3);

        $this->patchJson('/api/v1/tasks/'.$task->id, ['title' => 'Stale update', 'payload' => ['id' => 'update-cas-task', 'title' => 'Stale update'], 'client_updated_at' => $time->copy()->addMinutes(2)->toIso8601String(), 'sync_version' => 2])->assertStatus(409)->assertJsonPath('task.sync_version', 3)->assertJsonPath('task.title', 'First update');
    }

    public function test_stale_delete_returns_the_canonical_server_task_and_preserves_it(): void
    {
        $user = User::factory()->create();
        $task = Task::create(['user_id' => $user->id, 'client_id' => 'delete-cas-task', 'title' => 'Keep me', 'completed' => false, 'payload' => ['id' => 'delete-cas-task', 'title' => 'Keep me'], 'sync_version' => 5]);
        Sanctum::actingAs($user, ['tasks:write']);

        $this->deleteJson('/api/v1/tasks/by-client/delete-cas-task?sync_version=4')
            ->assertStatus(409)
            ->assertJsonPath('task.client_id', 'delete-cas-task')
            ->assertJsonPath('task.sync_version', 5)
            ->assertJsonPath('task.title', 'Keep me');

        $this->assertDatabaseHas('tasks', ['id' => $task->id, 'sync_version' => 5, 'title' => 'Keep me']);
        $this->assertDatabaseMissing('deleted_tasks', ['user_id' => $user->id, 'client_id' => 'delete-cas-task']);
    }

    public function test_timestamp_only_delete_cannot_remove_a_newer_server_task(): void
    {
        $user = User::factory()->create();
        $serverTime = Carbon::parse('2026-09-04T11:00:00Z');
        $task = Task::create(['user_id' => $user->id, 'client_id' => 'timestamp-delete-task', 'title' => 'Keep newer task', 'completed' => false, 'payload' => ['id' => 'timestamp-delete-task', 'title' => 'Keep newer task'], 'client_updated_at' => $serverTime, 'sync_version' => 1]);
        Sanctum::actingAs($user, ['tasks:write']);

        $this->deleteJson('/api/v1/tasks/by-client/timestamp-delete-task?client_updated_at='.$serverTime->copy()->subMinute()->toISOString())
            ->assertStatus(409)
            ->assertJsonPath('task.client_id', 'timestamp-delete-task')
            ->assertJsonPath('task.title', 'Keep newer task');

        $this->assertDatabaseHas('tasks', ['id' => $task->id, 'sync_version' => 1, 'title' => 'Keep newer task']);
        $this->assertDatabaseMissing('deleted_tasks', ['user_id' => $user->id, 'client_id' => 'timestamp-delete-task']);
    }

    public function test_deleting_by_client_id_creates_a_tombstone_and_blocks_stale_recreation(): void
    {
        $user = User::factory()->create(); $createdAt = Carbon::parse('2026-09-04T07:00:00Z');
        Task::create(['user_id' => $user->id, 'client_id' => 'deleted-task', 'title' => 'Delete me', 'completed' => false, 'payload' => ['id' => 'deleted-task', 'title' => 'Delete me'], 'client_updated_at' => $createdAt, 'sync_version' => 3]);
        Sanctum::actingAs($user, ['tasks:read', 'tasks:write']);
        $this->deleteJson('/api/v1/tasks/by-client/deleted-task')->assertOk();
        $this->assertDatabaseMissing('tasks', ['client_id' => 'deleted-task']);
        $this->assertDatabaseHas('deleted_tasks', ['user_id' => $user->id, 'client_id' => 'deleted-task', 'sync_version' => 4]);
        $this->getJson('/api/v1/tasks/deleted')->assertOk()->assertJsonPath('data.0.client_id', 'deleted-task')->assertJsonPath('data.0.sync_version', 4);
        $this->postJson('/api/v1/tasks', ['client_id' => 'deleted-task', 'title' => 'Old offline copy', 'completed' => false, 'payload' => ['id' => 'deleted-task', 'title' => 'Old offline copy', 'updatedAt' => $createdAt->toIso8601String()], 'client_updated_at' => $createdAt->toIso8601String(), 'sync_version' => 3])->assertStatus(409)->assertJsonPath('deleted', true)->assertJsonPath('sync_version', 4);
    }

    public function test_successful_mutation_is_replayed_for_the_same_idempotency_key(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['tasks:write']);
        $payload = ['client_id' => 'idempotent-task', 'title' => 'Exactly once', 'completed' => false, 'payload' => ['id' => 'idempotent-task', 'title' => 'Exactly once']];
        $this->withHeader('Idempotency-Key', 'operation-001')->postJson('/api/v1/tasks', $payload)->assertCreated();
        $this->withHeader('Idempotency-Key', 'operation-001')->postJson('/api/v1/tasks', $payload)->assertCreated()->assertJsonPath('task.client_id', 'idempotent-task');
        $this->assertDatabaseCount('tasks', 1);
        $this->assertDatabaseCount('sync_operations', 1);
    }

    public function test_reusing_an_idempotency_key_for_a_different_request_is_rejected(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['tasks:write']);
        $this->withHeader('Idempotency-Key', 'operation-002')->postJson('/api/v1/tasks', ['client_id' => 'task-a', 'title' => 'First', 'completed' => false, 'payload' => ['id' => 'task-a']])->assertCreated();
        $this->withHeader('Idempotency-Key', 'operation-002')->postJson('/api/v1/tasks', ['client_id' => 'task-b', 'title' => 'Second', 'completed' => false, 'payload' => ['id' => 'task-b']])->assertStatus(409);
        $this->assertDatabaseCount('tasks', 1);
    }

    public function test_overlong_idempotency_key_is_rejected_before_mutation(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['tasks:write']);

        $this->withHeader('Idempotency-Key', str_repeat('x', 101))
            ->postJson('/api/v1/tasks', ['client_id' => 'too-long-key', 'title' => 'Should not be created', 'completed' => false, 'payload' => ['id' => 'too-long-key']])
            ->assertStatus(422)
            ->assertJson(['message' => 'The Idempotency-Key header is too long.']);

        $this->assertDatabaseCount('tasks', 0);
        $this->assertDatabaseCount('sync_operations', 0);
    }
}