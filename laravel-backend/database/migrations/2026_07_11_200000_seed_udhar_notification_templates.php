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
                'name' => 'Udhar Ledger Updated',
                'template_key' => 'udhar_ledger_update',
                'subject' => 'Udhar Ledger Update',
                'short_keys' => '["merchant", "amount", "type"]',
                'email' => 'Hello, your ledger with [[merchant]] has been updated by [[amount]] ([[type]]). Log in to your app to see the details.',
                'sms' => 'Udhar Card: Ledger with [[merchant]] updated by [[amount]] ([[type]])',
                'in_app' => 'Ledger with [[merchant]] updated: [[amount]] ([[type]])',
                'push' => 'Ledger with [[merchant]] updated: [[amount]] ([[type]])',
                'status' => '{"mail":1,"sms":0,"in_app":1,"push":1}',
                'notify_for' => 0,
                'lang_code' => 'en',
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'language_id' => 1,
                'name' => 'Udhar Customer Synced',
                'template_key' => 'udhar_customer_sync',
                'subject' => 'New Udhar Account Linked',
                'short_keys' => '["merchant"]',
                'email' => 'Hello, your account has been linked to a new ledger created by [[merchant]]. Log in to your app to see the details.',
                'sms' => 'Udhar Card: New ledger account linked by [[merchant]]',
                'in_app' => 'New ledger account linked by [[merchant]]',
                'push' => 'New ledger account linked by [[merchant]]',
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
        DB::table('notification_templates')->whereIn('template_key', ['udhar_ledger_update', 'udhar_customer_sync'])->delete();
    }
};
