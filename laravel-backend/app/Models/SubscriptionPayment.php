<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubscriptionPayment extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_subscription_id',
        'merchant_id',
        'subscription_plan_id',
        'billing_cycle',
        'amount',
        'currency',
        'gateway',
        'external_order_id',
        'external_payment_id',
        'gateway_signature',
        'status',
        'paid_at',
        'raw_payload',
    ];

    protected $casts = [
        'amount' => 'float',
        'paid_at' => 'datetime',
        'raw_payload' => 'array',
    ];

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(MerchantSubscription::class, 'merchant_subscription_id');
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }
}
