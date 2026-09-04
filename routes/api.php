<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ReminderController;
use App\Http\Controllers\Api\TaskController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:6,1');
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:6,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);

        Route::get('/tasks', [TaskController::class, 'index'])->middleware('throttle:120,1');
        Route::get('/tasks/deleted', [TaskController::class, 'deleted'])->middleware('throttle:120,1');
        Route::post('/tasks', [TaskController::class, 'store'])->middleware('throttle:120,1');
        Route::delete('/tasks/by-client/{clientId}', [TaskController::class, 'destroyByClientId'])->middleware('throttle:120,1');
        Route::patch('/tasks/{task}', [TaskController::class, 'update'])->middleware('throttle:120,1');
        Route::delete('/tasks/{task}', [TaskController::class, 'destroy'])->middleware('throttle:120,1');

        Route::get('/reminders', [ReminderController::class, 'index'])->middleware('throttle:120,1');
        Route::post('/reminders', [ReminderController::class, 'store'])->middleware('throttle:120,1');
        Route::patch('/reminders/{reminder}', [ReminderController::class, 'update'])->middleware('throttle:120,1');
        Route::delete('/reminders/{reminder}', [ReminderController::class, 'destroy'])->middleware('throttle:120,1');
    });
});
