<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::table('notification_templates')->insert([
            [
                'language_id' => 1,
                'name' => 'Udhar Payment Reminder',
                'template_key' => 'udhar_payment_reminder',
                'subject' => 'Payment Due Reminder',
                'short_keys' => '["merchant", "amount"]',
                'email' => 'Hello, this is a friendly reminder that you have an outstanding balance of Rs. [[amount]] due with [[merchant]]. Please clear your dues as soon as possible.',
                'sms' => 'Udhar Card: Friendly reminder - You have an outstanding balance of Rs. [[amount]] due with [[merchant]].',
                'in_app' => 'Payment Reminder: Rs. [[amount]] due with [[merchant]]',
                'push' => 'Payment Reminder: Rs. [[amount]] due with [[merchant]]',
                'status' => '{"mail":1,"sms":0,"in_app":1,"push":1}',
                'notify_for' => 0,
                'lang_code' => 'en',
                'created_at' => now(),
                'updated_at' => now()
            ]
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('notification_templates')->where('template_key', 'udhar_payment_reminder')->delete();
    }
};
