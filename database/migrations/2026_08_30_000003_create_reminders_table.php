<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reminders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('task_id')->constrained()->cascadeOnDelete();
            $table->string('timezone', 64);
            $table->string('type', 20); // once, daily, weekly, weekdays
            $table->dateTimeTz('starts_at');
            $table->unsignedTinyInteger('hour')->nullable();
            $table->unsignedTinyInteger('minute')->nullable();
            $table->json('weekdays')->nullable();
            $table->unsignedInteger('snooze_minutes')->default(10);
            $table->boolean('enabled')->default(true);
            $table->timestamps();
            $table->index(['user_id', 'enabled']);
            $table->index(['task_id', 'enabled']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reminders');
    }
};
