<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'uuid',
        'merchant_id',
        'customer_id',
        'amount',
        'type', // given, received
        'payment_method', // cash, upi, bank_transfer, qr_code
        'remarks',
        'due_date',
        'gateway_tx_id',
        'status',
        'created_by',
        'verification_status',
    ];

    protected $casts = [
        'amount' => 'float',
        'due_date' => 'date',
    ];

    /**
     * Get the customer associated with the transaction.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
