<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UdharLedger extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'merchant_id',
        'type',
        'amount',
        'running_balance',
        'payment_method',
        'transaction_id',
        'transaction_date',
        'notes',
        'due_date',
        'created_by',
        'verification_status',
    ];

    protected $casts = [
        'amount' => 'decimal:8',
        'running_balance' => 'decimal:8',
        'transaction_date' => 'date',
        'due_date' => 'date',
    ];

    /**
     * Get the customer that this ledger entry belongs to.
     */
    public function customer()
    {
        return $this->belongsTo(UdharCustomer::class, 'customer_id');
    }

    /**
     * Get the merchant (User) that created this ledger entry.
     */
    public function merchant()
    {
        return $this->belongsTo(User::class, 'merchant_id');
    }

    /**
     * Recalculate all running balances and update outstanding balance for a customer.
     */
    public static function recalculateLedger($customerId)
    {
        $customer = UdharCustomer::findOrFail($customerId);
        $ledgers = self::where('customer_id', $customerId)->orderBy('id', 'asc')->get();

        $runningBalance = $customer->opening_balance;
        foreach ($ledgers as $ledger) {
            if ($ledger->type === 'credit') {
                $runningBalance += $ledger->amount;
            } else {
                $runningBalance -= $ledger->amount;
            }
            $ledger->running_balance = $runningBalance;
            $ledger->save();
        }

        $customer->outstanding_balance = $runningBalance;
        $customer->save();
    }
}
