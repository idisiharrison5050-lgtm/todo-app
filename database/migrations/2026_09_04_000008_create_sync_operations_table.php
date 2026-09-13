<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sync_operations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('operation_id', 100);
            $table->string('fingerprint', 64);
            $table->unsignedSmallInteger('status_code');
            $table->json('response_body');
            $table->timestamps();
            $table->unique(['user_id', 'operation_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sync_operations');
    }
};
