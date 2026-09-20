<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'is_shop_online')) {
                $table->boolean('is_shop_online')->default(true)->after('shop_name');
            }
            if (!Schema::hasColumn('users', 'shop_opening_time')) {
                $table->string('shop_opening_time', 20)->default('09:00 AM')->after('is_shop_online');
            }
            if (!Schema::hasColumn('users', 'shop_closing_time')) {
                $table->string('shop_closing_time', 20)->default('09:30 PM')->after('shop_opening_time');
            }
            if (!Schema::hasColumn('users', 'shop_closed_days')) {
                $table->string('shop_closed_days', 100)->default('Open All Days')->after('shop_closing_time');
            }
            if (!Schema::hasColumn('users', 'landmark')) {
                $table->string('landmark', 255)->nullable()->after('address_two');
            }
            if (!Schema::hasColumn('users', 'whatsapp_number')) {
                $table->string('whatsapp_number', 25)->nullable()->after('phone');
            }
            if (!Schema::hasColumn('users', 'shop_description')) {
                $table->text('shop_description')->nullable()->after('shop_closed_days');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $columns = [
                'is_shop_online',
                'shop_opening_time',
                'shop_closing_time',
                'shop_closed_days',
                'landmark',
                'whatsapp_number',
                'shop_description',
            ];
            foreach ($columns as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
