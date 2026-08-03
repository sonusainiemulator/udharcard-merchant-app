<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SubscriptionPlan extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'name',
        'description',
        'monthly_price',
        'yearly_price',
        'currency',
        'customer_limit',
        'features',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'monthly_price' => 'float',
        'yearly_price' => 'float',
        'customer_limit' => 'integer',
        'features' => 'array',
        'is_active' => 'boolean',
    ];

    public function subscriptions(): HasMany
    {
        return $this->hasMany(MerchantSubscription::class, 'subscription_plan_id');
    }
}
