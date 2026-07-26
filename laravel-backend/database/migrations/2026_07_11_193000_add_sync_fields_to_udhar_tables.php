<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('udhar_customers', function (Blueprint $table) {
            $table->unsignedBigInteger('customer_user_id')->nullable()->after('merchant_id')->index();
        });

        Schema::table('udhar_ledgers', function (Blueprint $table) {
            $table->enum('created_by', ['merchant', 'customer', 'system'])->default('merchant')->after('notes');
            $table->enum('verification_status', ['unverified', 'verified', 'disputed'])->default('unverified')->after('created_by');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('udhar_ledgers', function (Blueprint $table) {
            $table->dropColumn(['created_by', 'verification_status']);
        });

        Schema::table('udhar_customers', function (Blueprint $table) {
            $table->dropColumn('customer_user_id');
        });
    }
};
