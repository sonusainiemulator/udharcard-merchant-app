<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubscriptionRequest extends Model
{
    use HasFactory;

    protected $table = 'subscription_requests';

    protected $fillable = [
        'merchant_id',
        'subscription_plan_id',
        'requested_plan_code',
        'billing_cycle',
        'status',
        'note',
        'admin_remark',
        'approved_subscription_id',
        'resolved_at',
        'resolved_by',
    ];

    protected $casts = [
        'resolved_at' => 'datetime',
    ];

    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }

    public function merchant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'merchant_id');
    }
}
