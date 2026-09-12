<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('deleted_tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('client_id', 64);
            $table->timestamp('deleted_at');
            $table->unique(['user_id', 'client_id']);
            $table->index(['user_id', 'deleted_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('deleted_tasks');
    }
};
