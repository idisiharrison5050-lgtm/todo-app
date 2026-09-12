<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tasks', function (Blueprint $table) {
            $table->string('client_id', 64)->nullable()->after('id');
            $table->json('payload')->nullable()->after('completed');
            $table->unique(['user_id', 'client_id']);
        });
    }

    public function down(): void
    {
        Schema::table('tasks', function (Blueprint $table) {
            $table->dropUnique('tasks_user_id_client_id_unique');
            $table->dropColumn(['client_id', 'payload']);
        });
    }
};
