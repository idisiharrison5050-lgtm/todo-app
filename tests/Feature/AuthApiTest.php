<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\ResetPasswordNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_forgot_password_uses_a_generic_response_and_sends_a_reset_notification_for_existing_accounts(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'user@example.com']);

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'user@example.com'])
            ->assertOk()
            ->assertJson(['message' => 'If an account exists for that email, a password reset link has been sent.']);

        Notification::assertSentTo($user, ResetPasswordNotification::class);
    }

    public function test_forgot_password_does_not_reveal_unknown_accounts(): void
    {
        Notification::fake();

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'unknown@example.com'])
            ->assertOk()
            ->assertJson(['message' => 'If an account exists for that email, a password reset link has been sent.']);

        Notification::assertNothingSent();
    }

    public function test_valid_reset_token_changes_password_and_revokes_existing_tokens(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $user->createToken('old-device');
        $token = Password::createToken($user);

        $this->postJson('/api/v1/auth/reset-password', [
            'token' => $token,
            'email' => $user->email,
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertOk()->assertJson(['message' => 'Password reset successfully. Please sign in again.']);

        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->assertTrue(password_verify('new-password', $user->fresh()->password));
    }

    public function test_reset_password_requires_matching_password_confirmation(): void
    {
        $user = User::factory()->create(['password' => 'old-password']);
        $token = Password::createToken($user);

        $this->postJson('/api/v1/auth/reset-password', [
            'token' => $token,
            'email' => $user->email,
            'password' => 'new-password',
            'password_confirmation' => 'different-password',
        ])->assertStatus(422);

        $this->assertTrue(password_verify('old-password', $user->fresh()->password));
    }
}
