<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Reminder extends Model
{
    protected $fillable = [
        'user_id',
        'task_id',
        'timezone',
        'type',
        'starts_at',
        'hour',
        'minute',
        'weekdays',
        'snooze_minutes',
        'enabled',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'weekdays' => 'array',
            'enabled' => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function task()
    {
        return $this->belongsTo(Task::class);
    }
}
