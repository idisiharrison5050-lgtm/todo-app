<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tasks', function (Blueprint $table) {
            $table->string('client_id', 64)->nullable()->after('user_id');
            $table->json('payload')->nullable()->after('completed');
            $table->dateTime('client_updated_at')->nullable()->after('payload');
            $table->unique(['user_id', 'client_id']);
            $table->index(['user_id', 'updated_at']);
        });
    }

    public function down(): void
    {
        Schema::table('tasks', function (Blueprint $table) {
            $table->dropUnique(['user_id', 'client_id']);
            $table->dropIndex(['user_id', 'updated_at']);
            $table->dropColumn(['client_id', 'payload', 'client_updated_at']);
        });
    }
};
