<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('subscription_plans', function (Blueprint $table) {
            if (!Schema::hasColumn('subscription_plans', 'tag')) {
                $table->string('tag', 50)->nullable()->after('name');
            }
            if (!Schema::hasColumn('subscription_plans', 'tag_color')) {
                $table->string('tag_color', 30)->nullable()->after('tag');
            }
            if (!Schema::hasColumn('subscription_plans', 'badge')) {
                $table->string('badge', 50)->nullable()->after('tag_color');
            }
            if (!Schema::hasColumn('subscription_plans', 'subtitle')) {
                $table->string('subtitle')->nullable()->after('description');
            }
            if (!Schema::hasColumn('subscription_plans', 'trial_days')) {
                $table->unsignedInteger('trial_days')->default(0)->after('yearly_price');
            }
            if (!Schema::hasColumn('subscription_plans', 'feature_flags')) {
                $table->json('feature_flags')->nullable()->after('features');
            }
            if (!Schema::hasColumn('subscription_plans', 'sample_prompts')) {
                $table->json('sample_prompts')->nullable()->after('feature_flags');
            }
            if (!Schema::hasColumn('subscription_plans', 'cta_text')) {
                $table->string('cta_text', 50)->default('Subscribe Now')->after('sample_prompts');
            }
        });

        Schema::table('merchant_subscriptions', function (Blueprint $table) {
            if (!Schema::hasColumn('merchant_subscriptions', 'trial_ends_at')) {
                $table->timestamp('trial_ends_at')->nullable()->after('started_at');
            }
        });

        // Seed or update the 3 standard dynamic merchant plans
        $plans = [
            [
                'code' => 'basic',
                'name' => 'Basic Plan',
                'tag' => 'FREE',
                'tag_color' => '#1E293B',
                'badge' => 'FREE',
                'description' => 'Perfect for merchants who want a simple way to manage customer credit records.',
                'subtitle' => 'Perfect for merchants who want a simple way to manage customer credit records.',
                'monthly_price' => 0.00,
                'yearly_price' => 0.00,
                'currency' => 'INR',
                'trial_days' => 0,
                'customer_limit' => null,
                'features' => json_encode([
                    'Manually add and manage customer credit entries',
                    'Track outstanding balances',
                    'Access records from mobile, laptop, or desktop',
                    'Simple and easy-to-use credit management system',
                ]),
                'feature_flags' => json_encode([
                    'has_voice_entry' => false,
                    'has_soundbox' => false,
                    'has_desktop_access' => true,
                    'pdf_bill_access' => true,
                    'customer_limit' => null,
                ]),
                'sample_prompts' => null,
                'cta_text' => 'Get Started Free',
                'sort_order' => 1,
                'is_active' => true,
            ],
            [
                'code' => 'premium',
                'name' => 'Premium Plan',
                'tag' => 'MOST POPULAR',
                'tag_color' => '#EA580C',
                'badge' => 'VOICE',
                'description' => 'Manage your credit business faster with AI-powered voice assistance.',
                'subtitle' => 'Manage your credit business faster with AI-powered voice assistance.',
                'monthly_price' => 29.00,
                'yearly_price' => 299.00,
                'currency' => 'INR',
                'trial_days' => 7, // 7 Days Free Trial
                'customer_limit' => null,
                'features' => json_encode([
                    'Everything in the Basic Plan',
                    'Voice-based credit entry',
                    'Add customer transactions by speaking',
                    'Quick credit and payment tracking using voice commands',
                ]),
                'feature_flags' => json_encode([
                    'has_voice_entry' => true,
                    'has_soundbox' => false,
                    'has_desktop_access' => true,
                    'pdf_bill_access' => true,
                    'customer_limit' => null,
                ]),
                'sample_prompts' => json_encode([
                    'How much is pending from Ram?',
                    "Show today's credit entries",
                ]),
                'cta_text' => 'Subscribe Now',
                'sort_order' => 2,
                'is_active' => true,
            ],
            [
                'code' => 'gold',
                'name' => 'Gold Plan',
                'tag' => 'BEST VALUE',
                'tag_color' => '#D97706',
                'badge' => 'SOUND',
                'description' => 'The ultimate hands-free credit management solution for merchants.',
                'subtitle' => 'The ultimate hands-free credit management solution for merchants.',
                'monthly_price' => 129.00,
                'yearly_price' => 1299.00,
                'currency' => 'INR',
                'trial_days' => 0,
                'customer_limit' => null,
                'features' => json_encode([
                    'Everything in the Premium Plan',
                    'Free UdharCard Soundbox Device',
                    'Use the Soundbox as your dedicated voice assistant',
                    'Add and manage credit entries without using a phone or laptop',
                    'Check customer balances through voice commands',
                    'Faster and more convenient shop management',
                ]),
                'feature_flags' => json_encode([
                    'has_voice_entry' => true,
                    'has_soundbox' => true,
                    'has_desktop_access' => true,
                    'pdf_bill_access' => true,
                    'customer_limit' => null,
                ]),
                'sample_prompts' => json_encode([
                    'Add ₹500 credit to Ram',
                    'How much balance is pending from Ram?',
                ]),
                'cta_text' => 'Subscribe Now',
                'sort_order' => 3,
                'is_active' => true,
            ],
        ];

        foreach ($plans as $planData) {
            DB::table('subscription_plans')->updateOrInsert(
                ['code' => $planData['code']],
                array_merge($planData, [
                    'updated_at' => now(),
                ])
            );
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('subscription_plans', function (Blueprint $table) {
            $table->dropColumn([
                'tag',
                'tag_color',
                'badge',
                'subtitle',
                'trial_days',
                'feature_flags',
                'sample_prompts',
                'cta_text',
            ]);
        });

        Schema::table('merchant_subscriptions', function (Blueprint $table) {
            $table->dropColumn(['trial_ends_at']);
        });
    }
};
