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
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('description')->nullable();
            $table->decimal('monthly_price', 12, 2);
            $table->decimal('yearly_price', 12, 2);
            $table->string('currency', 10)->default('INR');
            $table->unsignedInteger('customer_limit')->nullable();
            $table->json('features')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('merchant_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('merchant_id')->index();
            $table->unsignedBigInteger('subscription_plan_id');
            $table->enum('billing_cycle', ['monthly', 'yearly']);
            $table->enum('status', ['pending', 'active', 'grace_period', 'expired', 'cancelled'])->default('pending');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('renews_at')->nullable();
            $table->timestamp('grace_ends_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('last_payment_at')->nullable();
            $table->boolean('auto_renew')->default(true);
            $table->string('external_subscription_id')->nullable()->index();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->foreign('subscription_plan_id')->references('id')->on('subscription_plans')->onDelete('cascade');
            $table->index(['merchant_id', 'status']);
        });

        Schema::create('subscription_payments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('merchant_subscription_id');
            $table->unsignedBigInteger('merchant_id')->index();
            $table->unsignedBigInteger('subscription_plan_id')->index();
            $table->enum('billing_cycle', ['monthly', 'yearly']);
            $table->decimal('amount', 12, 2);
            $table->string('currency', 10)->default('INR');
            $table->enum('gateway', ['razorpay'])->default('razorpay');
            $table->string('external_order_id')->nullable()->index();
            $table->string('external_payment_id')->nullable()->unique();
            $table->string('gateway_signature')->nullable();
            $table->enum('status', ['initiated', 'captured', 'failed', 'refunded'])->default('initiated');
            $table->timestamp('paid_at')->nullable();
            $table->json('raw_payload')->nullable();
            $table->timestamps();

            $table->foreign('merchant_subscription_id')->references('id')->on('merchant_subscriptions')->onDelete('cascade');
        });

        DB::table('subscription_plans')->insert([
            [
                'code' => 'starter',
                'name' => 'Starter',
                'description' => 'For new merchants with essential ledger tools.',
                'monthly_price' => 99,
                'yearly_price' => 999,
                'currency' => 'INR',
                'customer_limit' => 250,
                'features' => json_encode(['ledger', 'customer_management', 'reminders', 'basic_reports']),
                'sort_order' => 1,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'code' => 'growth',
                'name' => 'Growth',
                'description' => 'For growing stores with analytics and faster collections.',
                'monthly_price' => 299,
                'yearly_price' => 2999,
                'currency' => 'INR',
                'customer_limit' => 1000,
                'features' => json_encode(['ledger', 'customer_management', 'auto_reminders', 'advanced_reports', 'voice_entry']),
                'sort_order' => 2,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'code' => 'enterprise',
                'name' => 'Enterprise',
                'description' => 'For high volume merchants requiring full feature access.',
                'monthly_price' => 599,
                'yearly_price' => 5999,
                'currency' => 'INR',
                'customer_limit' => null,
                'features' => json_encode(['full_access', 'priority_support', 'api_access', 'nfc_ready']),
                'sort_order' => 3,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (!Schema::hasColumn('users', 'current_plan_code')) {
                    $table->string('current_plan_code')->nullable()->after('type');
                }
                if (!Schema::hasColumn('users', 'subscription_status')) {
                    $table->string('subscription_status')->nullable()->after('current_plan_code');
                }
                if (!Schema::hasColumn('users', 'subscription_renews_at')) {
                    $table->timestamp('subscription_renews_at')->nullable()->after('subscription_status');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (Schema::hasColumn('users', 'subscription_renews_at')) {
                    $table->dropColumn('subscription_renews_at');
                }
                if (Schema::hasColumn('users', 'subscription_status')) {
                    $table->dropColumn('subscription_status');
                }
                if (Schema::hasColumn('users', 'current_plan_code')) {
                    $table->dropColumn('current_plan_code');
                }
            });
        }

        Schema::dropIfExists('subscription_payments');
        Schema::dropIfExists('merchant_subscriptions');
        Schema::dropIfExists('subscription_plans');
    }
};
