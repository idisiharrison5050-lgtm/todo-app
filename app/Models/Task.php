<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    protected $fillable = [
        'user_id',
        'client_id',
        'title',
        'completed',
        'payload',
        'client_updated_at',
    ];

    protected function casts(): array
    {
        return [
            'completed' => 'boolean',
            'payload' => 'array',
            'client_updated_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reminders()
    {
        return $this->hasMany(Reminder::class);
    }
}
