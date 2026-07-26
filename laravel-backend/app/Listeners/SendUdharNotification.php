<?php

namespace App\Listeners;

use App\Events\UdharCustomerSynced;
use App\Events\UdharLedgerUpdated;
use App\Models\User;
use App\Traits\Notify;
use Illuminate\Support\Facades\Log;

class SendUdharNotification
{
    use Notify;

    /**
     * Handle UdharCustomerSynced events.
     */
    public function handleUdharCustomerSynced(UdharCustomerSynced $event)
    {
        try {
            $customer = $event->customer;
            
            // If the customer profile is linked to a registered global user
            if ($customer->customer_user_id) {
                $customerUser = User::find($customer->customer_user_id);
                if ($customerUser) {
                    $merchantName = $customer->merchant->username ?? 'A Merchant';
                    
                    // Dispatch FCM/Push/In-App alert to the customer user
                    $this->userFirebasePushNotification(
                        $customerUser,
                        'udhar_customer_sync',
                        ['merchant' => $merchantName]
                    );

                    $this->userPushNotification(
                        $customerUser,
                        'udhar_customer_sync',
                        ['merchant' => $merchantName]
                    );
                }
            }
        } catch (\Exception $e) {
            Log::error("FCM Sync Notification failed: " . $e->getMessage());
        }
    }

    /**
     * Handle UdharLedgerUpdated events.
     */
    public function handleUdharLedgerUpdated(UdharLedgerUpdated $event)
    {
        try {
            $ledger = $event->ledger;
            
            // Notify the customer when the merchant creates a ledger entry
            $customer = $ledger->customer;
            if ($customer && $customer->customer_user_id) {
                $customerUser = User::find($customer->customer_user_id);
                if ($customerUser) {
                    $merchantName = $ledger->merchant->username ?? 'A Merchant';
                    $amountStr = number_format($ledger->amount, 2);
                    $typeStr = $ledger->type === 'credit' ? 'credit' : 'debit';

                    $this->userFirebasePushNotification(
                        $customerUser,
                        'udhar_ledger_update',
                        [
                            'merchant' => $merchantName,
                            'amount' => $amountStr,
                            'type' => $typeStr
                        ]
                    );

                    $this->userPushNotification(
                        $customerUser,
                        'udhar_ledger_update',
                        [
                            'merchant' => $merchantName,
                            'amount' => $amountStr,
                            'type' => $typeStr
                        ]
                    );
                }
            }
        } catch (\Exception $e) {
            Log::error("FCM Ledger Notification failed: " . $e->getMessage());
        }
    }
}
