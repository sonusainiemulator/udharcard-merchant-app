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
        'tag',
        'tag_color',
        'badge',
        'description',
        'subtitle',
        'monthly_price',
        'yearly_price',
        'currency',
        'trial_days',
        'customer_limit',
        'features',
        'feature_flags',
        'sample_prompts',
        'cta_text',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'monthly_price' => 'float',
        'yearly_price' => 'float',
        'trial_days' => 'integer',
        'customer_limit' => 'integer',
        'features' => 'array',
        'feature_flags' => 'array',
        'sample_prompts' => 'array',
        'is_active' => 'boolean',
    ];

    public function subscriptions(): HasMany
    {
        return $this->hasMany(MerchantSubscription::class, 'subscription_plan_id');
    }

    public function isFree(): bool
    {
        return (float) $this->monthly_price <= 0 && (float) $this->yearly_price <= 0;
    }

    public function hasTrial(): bool
    {
        return (int) $this->trial_days > 0;
    }

    public function hasFeature(string $featureKey): bool
    {
        $flags = $this->feature_flags ?? [];
        return !empty($flags[$featureKey]);
    }
}
