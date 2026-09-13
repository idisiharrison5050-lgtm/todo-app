<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SyncOperation extends Model
{
    protected $fillable = [
        'user_id',
        'operation_id',
        'fingerprint',
        'status_code',
        'response_body',
    ];

    protected $casts = [
        'response_body' => 'array',
        'status_code' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
