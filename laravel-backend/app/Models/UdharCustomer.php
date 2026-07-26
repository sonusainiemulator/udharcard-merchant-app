<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UdharCustomer extends Model
{
    use HasFactory;

    protected $fillable = [
        'merchant_id',
        'customer_user_id',
        'name',
        'phone',
        'email',
        'image',
        'image_driver',
        'credit_limit',
        'outstanding_balance',
        'opening_balance',
        'status',
        'due_date',
    ];

    protected $casts = [
        'credit_limit' => 'decimal:8',
        'outstanding_balance' => 'decimal:8',
        'opening_balance' => 'decimal:8',
        'due_date' => 'date',
    ];

    /**
     * Get the merchant (User) that owns the customer.
     */
    public function merchant()
    {
        return $this->belongsTo(User::class, 'merchant_id');
    }

    /**
     * Get the global customer user account (User) linked to this contact.
     */
    public function customerUser()
    {
        return $this->belongsTo(User::class, 'customer_user_id');
    }

    /**
     * Get the ledger entries (credit/debit transactions) for the customer.
     */
    public function ledgers()
    {
        return $this->hasMany(UdharLedger::class, 'customer_id')->orderBy('created_at', 'desc');
    }

    public function getImage(): string
    {
        return getFile($this->image_driver, $this->image);
    }
}
