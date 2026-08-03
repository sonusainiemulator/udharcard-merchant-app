<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('work_list_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('merchant_id')->index();
            $table->string('client_local_id')->nullable();
            $table->unsignedBigInteger('customer_id')->nullable()->index();
            $table->string('title');
            $table->text('note')->nullable();
            $table->date('due_date')->nullable()->index();
            $table->enum('status', ['pending', 'completed'])->default('pending')->index();
            $table->enum('priority', ['low', 'medium', 'high'])->default('medium');
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['merchant_id', 'client_local_id']);
            $table->foreign('customer_id')->references('id')->on('udhar_customers')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('work_list_items');
    }
};