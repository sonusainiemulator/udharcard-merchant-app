<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_id',
        'customer_user_id',
        'name',
        'phone',
        'email',
        'opening_balance',
        'outstanding_balance',
        'credit_limit',
    ];

    protected $casts = [
        'opening_balance' => 'float',
        'outstanding_balance' => 'float',
        'credit_limit' => 'float',
    ];

    /**
     * Get transactions related to the customer.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class)->orderBy('created_at', 'desc');
    }

    /**
     * Get merchant who owns the customer.
     */
    public function merchant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'merchant_id');
    }
}
