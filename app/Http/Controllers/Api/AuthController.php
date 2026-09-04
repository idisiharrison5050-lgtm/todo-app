<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate(['name' => ['required', 'string', 'max:100'], 'email' => ['required', 'email', 'max:255', 'unique:users,email'], 'password' => ['required', 'string', 'min:8', 'confirmed'], 'device_name' => ['required', 'string', 'max:100']]);
        $user = User::create(['name' => trim($validated['name']), 'email' => strtolower(trim($validated['email'])), 'password' => Hash::make($validated['password'])]);
        $token = $user->createToken($validated['device_name'], ['tasks:read', 'tasks:write'])->plainTextToken;
        return response()->json(['user' => $user->only(['id', 'name', 'email']), 'token' => $token], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate(['email' => ['required', 'email'], 'password' => ['required', 'string'], 'device_name' => ['required', 'string', 'max:100']]);
        $user = User::where('email', strtolower(trim($validated['email'])))->first();
        if (! $user || ! Hash::check($validated['password'], $user->password)) throw ValidationException::withMessages(['email' => ['The provided credentials are incorrect.']]);
        $token = $user->createToken($validated['device_name'], ['tasks:read', 'tasks:write'])->plainTextToken;
        return response()->json(['user' => $user->only(['id', 'name', 'email']), 'token' => $token]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $validated = $request->validate(['email' => ['required', 'email', 'max:255']]);
        $email = strtolower(trim($validated['email']));
        $user = User::where('email', $email)->first();
        if ($user) Password::sendResetLink(['email' => $email]);
        return response()->json(['message' => 'If an account exists for that email, a password reset link has been sent.']);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate(['token' => ['required', 'string'], 'email' => ['required', 'email', 'max:255'], 'password' => ['required', 'string', 'min:8', 'confirmed']]);
        $status = Password::reset(['email' => strtolower(trim($validated['email'])), 'password' => $validated['password'], 'password_confirmation' => $validated['password'], 'token' => $validated['token']], function (User $user, string $password): void {
            $user->forceFill(['password' => $password, 'remember_token' => Str::random(60)])->save();
            $user->tokens()->delete();
            event(new PasswordReset($user));
        });
        if ($status !== Password::PASSWORD_RESET) return response()->json(['message' => 'The password reset link is invalid or has expired.'], 422);
        return response()->json(['message' => 'Password reset successfully. Please sign in again.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()->only(['id', 'name', 'email'])]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();
        return response()->json(['message' => 'Signed out.']);
    }
}
