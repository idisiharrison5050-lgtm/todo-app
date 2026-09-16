<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class IdempotencyApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_same_idempotency_key_is_scoped_to_the_authenticated_user(): void
    {
        $firstUser = User::factory()->create();
        $secondUser = User::factory()->create();

        Sanctum::actingAs($firstUser, ['tasks:write']);
        $this->withHeader('Idempotency-Key', 'shared-operation-001')
            ->postJson('/api/v1/tasks', [
                'client_id' => 'first-user-task',
                'title' => 'First user task',
                'completed' => false,
                'payload' => ['id' => 'first-user-task', 'title' => 'First user task'],
            ])
            ->assertCreated();

        Sanctum::actingAs($secondUser, ['tasks:write']);
        $this->withHeader('Idempotency-Key', 'shared-operation-001')
            ->postJson('/api/v1/tasks', [
                'client_id' => 'second-user-task',
                'title' => 'Second user task',
                'completed' => false,
                'payload' => ['id' => 'second-user-task', 'title' => 'Second user task'],
            ])
            ->assertCreated()
            ->assertJsonPath('task.client_id', 'second-user-task');

        $this->assertDatabaseCount('tasks', 2);
        $this->assertDatabaseCount('sync_operations', 2);
        $this->assertDatabaseHas('sync_operations', [
            'user_id' => $firstUser->id,
            'operation_id' => 'shared-operation-001',
        ]);
        $this->assertDatabaseHas('sync_operations', [
            'user_id' => $secondUser->id,
            'operation_id' => 'shared-operation-001',
        ]);
    }
}
