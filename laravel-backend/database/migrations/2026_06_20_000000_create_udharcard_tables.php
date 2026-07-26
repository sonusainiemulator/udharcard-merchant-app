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
        // Customers table
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('merchant_id')->index(); // Links to merchants table
            $table->string('name');
            $table->string('phone');
            $table->string('email')->nullable();
            $table->decimal('opening_balance', 12, 2)->default(0.00);
            $table->decimal('outstanding_balance', 12, 2)->default(0.00);
            $table->decimal('credit_limit', 12, 2)->default(5000.00);
            $table->timestamps();

            // Indexing for faster ledger queries
            $table->index(['merchant_id', 'phone']);
        });

        // Transactions table (debit/credit ledger log)
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('merchant_id')->index();
            $table->unsignedBigInteger('customer_id')->index();
            $table->decimal('amount', 12, 2);
            $table->enum('type', ['given', 'received']); // given = credit (udhar diya), received = debit (payment received)
            $table->enum('payment_method', ['cash', 'upi', 'bank_transfer', 'qr_code'])->default('cash');
            $table->string('remarks')->nullable();
            $table->date('due_date')->nullable();
            $table->string('gateway_tx_id')->nullable()->unique(); // Settle reference ID for Razorpay/UPI
            $table->enum('status', ['pending', 'completed', 'failed'])->default('completed');
            $table->timestamps();

            // Foreign keys
            $table->foreign('customer_id')->references('id')->on('customers')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('customers');
    }
};
