<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MerchantSubscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_id',
        'subscription_plan_id',
        'billing_cycle',
        'status',
        'started_at',
        'trial_ends_at',
        'renews_at',
        'grace_ends_at',
        'cancelled_at',
        'last_payment_at',
        'auto_renew',
        'external_subscription_id',
        'meta',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'trial_ends_at' => 'datetime',
        'renews_at' => 'datetime',
        'grace_ends_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'last_payment_at' => 'datetime',
        'auto_renew' => 'boolean',
        'meta' => 'array',
    ];

    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(SubscriptionPayment::class, 'merchant_subscription_id');
    }

    public function isTrial(): bool
    {
        if ($this->status === 'trial') {
            return $this->trial_ends_at ? now()->lte($this->trial_ends_at) : true;
        }
        return false;
    }

    public function isExpired(): bool
    {
        if ($this->status === 'expired') {
            return true;
        }
        if ($this->status === 'trial' && $this->trial_ends_at && now()->gt($this->trial_ends_at)) {
            return true;
        }
        if ($this->renews_at && now()->gt($this->renews_at) && $this->status !== 'active') {
            return true;
        }
        return false;
    }

    public function remainingTrialDays(): int
    {
        if (!$this->isTrial() || !$this->trial_ends_at) {
            return 0;
        }
        return max(0, (int) now()->diffInDays($this->trial_ends_at, false) + 1);
    }
}
