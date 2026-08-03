<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class WorkListItem extends Model
{
    use HasFactory;
    use SoftDeletes;

    protected $fillable = [
        'merchant_id',
        'client_local_id',
        'customer_id',
        'title',
        'note',
        'due_date',
        'status',
        'priority',
    ];

    protected $casts = [
        'due_date' => 'date',
    ];

    public function merchant()
    {
        return $this->belongsTo(User::class, 'merchant_id');
    }

    public function customer()
    {
        return $this->belongsTo(UdharCustomer::class, 'customer_id');
    }
}