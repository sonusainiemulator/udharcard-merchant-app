<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Jobs\UserAllRecordDeleteJob;
use App\Models\ApiOrder;
use App\Models\BasicControl;
use App\Models\BillPay;
use App\Models\ChargesLimit;
use App\Models\CommissionEntry;
use App\Models\Currency;
use App\Models\Deposit;
use App\Models\Escrow;
use App\Models\Exchange;
use App\Models\Gateway;
use App\Models\Invoice;
use App\Models\Kyc;
use App\Models\Language;
use App\Models\NotificationTemplate;
use App\Models\ProductOrder;
use App\Models\QRCode;
use App\Models\RedeemCode;
use App\Models\RequestMoney;
use App\Models\Transaction;
use App\Models\Transfer;
use App\Models\TwoFactorSetting;
use App\Models\User;
use App\Models\UserKyc;
use App\Models\VirtualCardOrder;
use App\Models\VirtualCardTransaction;
use App\Models\Voucher;
use App\Models\Wallet;
use App\Traits\ApiValidation;
use App\Traits\ChargeLimitTrait;
use App\Traits\Upload;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Stevebauman\Purify\Facades\Purify;

class HomeController extends Controller
{
    use ApiValidation, ChargeLimitTrait, Upload;

    public function basic()
    {
        try {
            $common = ['transfer', 'request', 'exchange', 'redeem', 'escrow', 'voucher', 'deposit', 'payout',
                'invoice', 'store', 'qr_payment', 'virtual_card', 'bill_payment', 'cash_in', 'cash_out', 'make_payment'
            ];

            $table = (new BasicControl)->getTable();
            $columns = Schema::getColumnListing($table);
            $allowed = array_intersect($common, $columns);

            if (empty($allowed)) {
                // If no columns match, provide default service statuses or empty object
                $data['service'] = (object) array_fill_keys($common, 0);
            } else {
                $data['service'] = BasicControl::first($allowed);
            }
            
            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function dashboard()
    {
        try {
            $data['wallets'] = Wallet::with('currency:id,name,code,symbol,logo,driver')
                ->select('id', 'balance as totalBalance', 'user_id', 'currency_id')
                ->where('user_id', auth()->id())
                ->customOrder()
                ->get()
                ->map(function ($wallet) {
                    $wallet->currency->image = $wallet?->currency?->getImage();
                    return $wallet;
                });

            $recentRecipients = Transfer::where('sender_id', auth()->id())->pluck('receiver_id')->toArray();
            if (empty($recentRecipients)) {
                $data['recipients'] = [];
            } else {
                $data['recipients'] = User::query()
                    ->where('type', 'user')
                    ->select('id', 'type', 'firstname', 'lastname', 'username', 'email', 'image', 'image_driver', 'status')
                    ->whereIn('id', $recentRecipients)
                    ->where('status', 1)
                    ->whereNot('id', auth()->id())
                    ->limit(5)
                    ->get()
                    ->map(function ($user) {
                        $user->imgUrl = $user->getImage();
                        return $user;
                    });
            }

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function getChargeLimit(Request $request)
    {
        try {
            $amount = $request->amount;
            $currency_id = $request->currency_id;
            $transaction_type_id = $request->transaction_type_id;
            $charge_from = $request->charge_from;
            $methodId = $request->gateway_id ?? null;

            if ($methodId) {
                $data['chargesLimit'] = ChargesLimit::with('currency')
                    ->where(['currency_id' => $currency_id, 'transaction_type_id' => $transaction_type_id, 'payment_method_id' => $methodId, 'is_active' => 1])
                    ->first();
            } else {
                $data['chargesLimit'] = ChargesLimit::with('currency')
                    ->where(['currency_id' => $currency_id, 'transaction_type_id' => $transaction_type_id, 'is_active' => 1])
                    ->first();
            }

            return response()->json($this->withSuccess($data));

            $result = $this->checkAmountValidate($amount, $currency_id, $transaction_type_id, $charge_from, $methodId);
            if (!$result['status']) {
                return response()->json($this->withErrors($result['message']));
            }
            $result['chargesLimit'] = $data['chargesLimit'];

            return response()->json($this->withSuccess($result));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function getQrPaymentList(Request $request)
    {
        try {
            $array = [];
            $search = $request->all();
            $dateSearch = $request->datetrx;
            $date = preg_match("/^[0-9]{2,4}\-[0-9]{1,2}\-[0-9]{1,2}$/", $dateSearch);

            $data['status'] = ['Pending ' => 0, 'Complete' => 1];
            $data['qrPayments'] = tap(QRCode::query()
                ->where('user_id', auth()->id())
                ->when(isset($search['email']), function ($query) use ($search) {
                    return $query->where("email", $search['email']);
                })
                ->when(isset($search['gateway']), function ($query) use ($search) {
                    return $query->where("gateway_id", $search['gateway']);
                })
                ->when($date == 1, function ($query) use ($dateSearch) {
                    return $query->whereDate("created_at", $dateSearch);
                })
                ->orderBy('id', 'desc')
                ->paginate(20), function ($paginatedInstance) use ($array) {
                return $paginatedInstance->getCollection()->transform(function ($query) use ($array) {
                    $array['senderEmail'] = $query->email ?? 'N/A';
                    $array['receiverName'] = $query->user->name ?? 'N/A';
                    $array['amount'] = getAmount($query->amount) ?? 'N/A';
                    $array['currency'] = optional($query->currency)->code;
                    $array['charge'] = getAmount($query->charge) ?? 'N/A';
                    $array['gateway'] = optional($query->gateway)->name ?? 'N/A';
                    $array['status'] = $query->status ?? 'N/A';
                    $array['createdTime'] = $query->created_at;
                    return $array;
                });
            });

            $data['gateways'] = Gateway::select(['id', 'status', 'name'])->where('status', 1)->get();

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function getTransaction()
    {
        try {
            $user = Auth::user();
            $data['currencies'] = Currency::select('id', 'code', 'name')->orderBy('code', 'ASC')->get();

            $array = [];
            $data['transactions'] = tap(Transaction::with(['transactional' => function (MorphTo $morphTo) {
                $morphTo->morphWith([
                    CommissionEntry::class => ['sender', 'receiver', 'currency'],
                    Transfer::class => ['sender', 'receiver', 'currency'],
                    RequestMoney::class => ['sender', 'receiver', 'currency'],
                    RedeemCode::class => ['sender', 'receiver', 'currency'],
                    Escrow::class => ['sender', 'receiver', 'currency'],
                    Voucher::class => ['sender', 'receiver', 'currency'],
                    Deposit::class => ['sender', 'receiver', 'currency'],
                    Exchange::class => ['user', 'fromWallet', 'toWallet'],
                    Invoice::class => ['sender', 'currency'],
                    QRCode::class => ['user', 'currency'],
                    ProductOrder::class => ['user'],
                    VirtualCardTransaction::class => ['user', 'currency'],
                    VirtualCardOrder::class => ['user', 'chargeCurrency'],
                    BillPay::class => ['user', 'baseCurrency'],
                    ApiOrder::class => ['user', 'currency'],
                ]);
            }])
                ->whereHasMorph('transactional',
                    [
                        CommissionEntry::class,
                        Transfer::class,
                        RequestMoney::class,
                        RedeemCode::class,
                        Escrow::class,
                        Voucher::class,
                        Deposit::class,
                        Exchange::class,
                        Invoice::class,
                        QRCode::class,
                        ProductOrder::class,
                        VirtualCardTransaction::class,
                        VirtualCardOrder::class,
                        BillPay::class,
                        ApiOrder::class,
                    ], function ($query, $type) use ($user) {
                        if ($type == CommissionEntry::class) {
                            $query->where(function ($query) use ($user) {
                                $query->where('from_user', '=', $user->id);
                                $query->orWhere('to_user', '=', $user->id);
                            });
                        } elseif ($type === Transfer::class || $type === RequestMoney::class || $type === RedeemCode::class || $type === Escrow::class || $type === Voucher::class) {
                            $query->where(function ($query) use ($user) {
                                $query->where('sender_id', '=', $user->id);
                                $query->orWhere('receiver_id', '=', $user->id);
                            });
                        } elseif ($type === Deposit::class || $type === Exchange::class || $type === ProductOrder::class || $type === QRCode::class || $type === VirtualCardTransaction::class || $type === VirtualCardOrder::class
                            || $type === BillPay::class || $type === ApiOrder::class) {
                            $query->where('user_id', $user->id);
                        } elseif ($type === Invoice::class) {
                            $query->where('sender_id', $user->id);
                        }
                    })
                ->latest()
                ->paginate(20), function ($paginatedInstance) use ($array) {
                return $paginatedInstance->getCollection()->transform(function ($value) use ($array) {
                    if ($value->transactional_type == Exchange::class) {
                        $array['sender'] = optional(optional(optional($value->transactional)->fromWallet)->currency)->name ?? 'N/A';
                    } elseif ($value->transactional_type == Invoice::class) {
                        $array['sender'] = optional($value->transactional->sender)->name ?? 'N/A';
                    } elseif ($value->transactional_type == ProductOrder::class || $value->transactional_type == QRCode::class) {
                        $array['sender'] = optional($value->transactional)->email ?? 'N/A';
                    } elseif ($value->transactional_type == VirtualCardTransaction::class) {
                        $array['sender'] = optional($value->transactional->user)->name ?? 'N/A';
                    } elseif ($value->transactional_type == 'App\Models\VirtualCardOrder' || ($value->transactional_type == BillPay::class && $value->currency_code == null)) {
                        $array['sender'] = 'Admin';
                    } elseif ($value->transactional_type == Deposit::class && optional($value->transactional)->card_order_id != null) {
                        $array['sender'] = optional(optional($value->transactional)->receiver)->name ?? 'N/A';
                    } elseif ($value->transactional_type == BillPay::class && $value->currency_code != null) {
                        $array['sender'] = optional($value->transactional->user)->name ?? 'N/A';
                    } else {
                        $array['sender'] = optional(optional($value->transactional)->sender)->name ?? 'N/A';
                    }

                    if ($value->transactional_type == Exchange::class) {
                        $array['receiver'] = optional(optional(optional($value->transactional)->toWallet)->currency)->name ?? 'N/A';
                    } elseif ($value->transactional_type == ProductOrder::class || $value->transactional_type == ApiOrder::class || $value->transactional_type == QRCode::class || $value->transactional_type == VirtualCardOrder::class) {
                        $array['receiver'] = optional($value->transactional->user)->name ?? 'N/A';
                    } elseif ($value->transactional_type == Deposit::class && optional($value->transactional)->card_order_id != null) {
                        $array['receiver'] = 'Admin';
                    } elseif ($value->transactional_type == BillPay::class && $value->currency_code == null) {
                        $array['receiver'] = optional($value->transactional->user)->name ?? 'N/A';
                    } else {
                        $array['receiver'] = optional(optional($value->transactional)->receiver)->name ?? 'N/A';
                    }

                    if ($value->transactional_type == ProductOrder::class || $value->transactional_type == QRCode::class || $value->transactional_type == VirtualCardTransaction::class) {
                        $array['receiverEmail'] = '-';
                    } elseif ($value->transactional_type == VirtualCardOrder::class || $value->transactional_type == ApiOrder::class) {
                        $array['receiverEmail'] = optional($value->transactional->user)->email ?? 'N/A';
                    } elseif ($value->transactional_type == Deposit::class && optional($value->transactional)->card_order_id != null) {
                        $array['receiverEmail'] = '-';
                    } elseif ($value->transactional_type == BillPay::class && $value->currency_code == null) {
                        $array['receiverEmail'] = optional($value->transactional->user)->email ?? 'N/A';
                    } else {
                        $array['receiverEmail'] = optional($value->transactional)->email ?? optional($value->transactional)->customer_email;
                    }

                    $array['transactionId'] = $value->trx_id ?? $value->transactional?->utr ?? $value->transactional?->has_slug ?? '-';

                    if ($value->transactional_type == 'App\Models\VirtualCardOrder') {
                        $array['amount'] = getAmount($value->amount);
                        $array ['currency'] = optional($value->transactional)->currency;
                    } elseif ($value->transactional_type == 'App\Models\BillPay' && $value->currency_code != null) {
                        $array['amount'] = getAmount(optional($value->transactional)->amount);
                        $array ['currency'] = $value->currency_code;
                    } elseif ($value->transactional_type == 'App\Models\BillPay' && $value->currency_code == null) {
                        $array['amount'] = getAmount(optional($value->transactional)->amount);
                        $array['currency'] = optional($value->transactional->baseCurrency)->code;
                    } elseif (optional($value->transactional)->amount != 0) {
                        $array['amount'] = getAmount(optional($value->transactional)->amount);
                        $array['currency'] = optional(optional($value->transactional)->currency)->code;
                    } else {
                        if ($value->transactional_type == 'App\Models\ProductOrder') {
                            $array['amount'] = getAmount(optional($value->transactional)->total_amount) + getAmount(optional($value->transactional)->shipping_charge);
                            $array['currency'] = optional(optional($value->transactional)->currency)->code;
                        } else {
                            $array['amount'] = getAmount(optional($value->transactional)->grand_total);
                            $array['currency'] = optional(optional($value->transactional)->currency)->code;
                        }
                    }

                    if ($value->transactional_type == QRCode::class) {
                        $array['type'] = 'QR Payment';
                    } elseif ($value->transactional_type == VirtualCardOrder::class || ($value->transactional_type == Deposit::class && optional($value->transactional)->card_order_id != null)) {
                        $array['type'] = 'VirtualCard';
                    } else {
                        $array['type'] = str_replace('App\Models\\', '', $value->transactional_type);
                    }

                    if ($value->transactional_type == 'App\Models\Invoice') {
                        $array['status'] = ucfirst($value->transactional->status);
                    } elseif ($value->transactional_type == 'App\Models\Voucher') {
                        if ($value->transactional->status) {
                            $array['status'] = 'Success';
                        } else {
                            $array['status'] = 'Pending';
                        }
                    } elseif ($value->transactional_type == 'App\Models\ProductOrder' || $value->transactional_type == 'App\Models\QRCode' || $value->transactional_type == 'App\Models\ApiOrder') {
                        if ($value->transactional->status == 1) {
                            $array['status'] = 'Paid';
                        } else {
                            $array['status'] = 'Pending';
                        }
                    } elseif ($value->transactional_type == 'App\Models\VirtualCardTransaction') {
                        $array['status'] = 'Completed';
                    } elseif ($value->transactional_type == 'App\Models\VirtualCardOrder') {
                        $array['status'] = 'Return';
                    } elseif ($value->transactional_type == Deposit::class && optional($value->transactional)->card_order_id != null) {
                        $array['status'] = 'Send';
                    } elseif ($value->transactional_type == 'App\Models\BillPay' && $value->currency_code != null) {
                        $array['status'] = 'Paid';
                    } elseif ($value->transactional_type == 'App\Models\BillPay' && $value->currency_code == null) {
                        $array['status'] = 'Return';
                    }

                    $array['createdTime'] = $value->created_at;
                    return $array;
                });
            });

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function getTransactionSearch(Request $request)
    {
        $filterData = $this->_filter($request);
        $transactions = $filterData['transactions']->latest()->paginate(20);

        $data['transactions'] = $transactions->through(function ($value) {
            $transactional = $value->transactional;
            $type = $value->transactional_type;
            $isBillPay = $type == BillPay::class;
            $isDepositWithCard = $type == Deposit::class && optional($transactional)->card_order_id != null;

            return [
                'sender' => match ($type) {
                    Exchange::class => $transactional?->fromWallet?->currency?->name ?? 'N/A',
                    Invoice::class => optional($transactional->sender)->name ?? 'N/A',
                    ProductOrder::class, QRCode::class => optional($transactional)->email ?? 'N/A',
                    VirtualCardTransaction::class => optional($transactional->user)->name ?? 'N/A',
                    VirtualCardOrder::class, $isBillPay && !$value->currency_code => 'Admin',
                    Deposit::class => optional($transactional->receiver)->name ?? 'N/A',
                    default => optional($transactional->sender)->name ?? 'N/A'
                },
                'receiver' => match ($type) {
                    Exchange::class => optional($transactional->toWallet->currency)->name ?? 'N/A',
                    ProductOrder::class, ApiOrder::class, QRCode::class, VirtualCardOrder::class => optional($transactional->user)->name ?? 'N/A',
                    $isDepositWithCard => 'Admin',
                    $isBillPay && !$value->currency_code => optional($transactional->user)->name ?? 'N/A',
                    default => optional($transactional->receiver)->name ?? 'N/A'
                },
                'receiverEmail' => match ($type) {
                    ProductOrder::class, QRCode::class, VirtualCardTransaction::class, $isDepositWithCard => '-',
                    VirtualCardOrder::class, ApiOrder::class, $isBillPay && !$value->currency_code => optional($transactional->user)->email ?? 'N/A',
                    default => $transactional->email ?? $transactional->customer_email ?? 'N/A'
                },
                'transactionId' => $value->trx_id ?? $transactional?->utr ?? $transactional?->has_slug ?? '-',
                'amount' => getAmount(optional($transactional)->amount ?: optional($transactional)->grand_total ?: (optional($transactional)->total_amount ?? 0) + (optional($transactional)->shipping_charge ?? 0)),
                'currency' => $value->currency?->code ?? $transactional?->currency?->code ?? optional($transactional->baseCurrency)->code ?? null,
                'type' => match ($type) {
                    QRCode::class => 'QR Payment',
                    VirtualCardOrder::class, $isDepositWithCard => 'VirtualCard',
                    default => class_basename($type)
                },
                'trx_type' => $value->trx_type,
                'remarks' => $value->remarks,
                'createdTime' => $value->created_at
            ];
        });

        return response()->json($this->withSuccess($data));
    }


    public function _filter($request)
    {
        $user = Auth::user();
        $currencies = Currency::select('id', 'code', 'name')->orderBy('code', 'ASC')->get();
        $search = $request->all();
        $created_date = isset($search['created_at']) ? preg_match("/^[0-9]{2,4}-[0-9]{1,2}-[0-9]{1,2}$/", $search['created_at']) : 0;

        if (isset($search['type'])) {
            if ($search['type'] == 'Transfer') {
                $morphWith = [Transfer::class => ['sender', 'receiver', 'currency']];
                $whereHasMorph = [Transfer::class];
            } elseif ($search['type'] == 'RequestMoney') {
                $morphWith = [RequestMoney::class => ['sender', 'receiver', 'currency']];
                $whereHasMorph = [RequestMoney::class];
            } elseif ($search['type'] == 'RedeemCode') {
                $morphWith = [RedeemCode::class => ['sender', 'receiver', 'currency']];
                $whereHasMorph = [RedeemCode::class];
            } elseif ($search['type'] == 'Escrow') {
                $morphWith = [Escrow::class => ['sender', 'receiver', 'currency']];
                $whereHasMorph = [Escrow::class];
            } elseif ($search['type'] == 'Voucher') {
                $morphWith = [Voucher::class => ['sender', 'receiver', 'currency']];
                $whereHasMorph = [Voucher::class];
            } elseif ($search['type'] == 'Invoice') {
                $morphWith = [Invoice::class => ['sender', 'currency']];
                $whereHasMorph = [Invoice::class];
            } elseif ($search['type'] == 'QRCode') {
                $morphWith = [QRCode::class => ['user', 'currency']];
                $whereHasMorph = [QRCode::class];
            } elseif ($search['type'] == 'ProductOrder') {
                $morphWith = [ProductOrder::class => ['user']];
                $whereHasMorph = [ProductOrder::class];
            } elseif ($search['type'] == 'VirtualCardTransaction') {
                $morphWith = [VirtualCardTransaction::class => ['user', 'currency']];
                $whereHasMorph = [VirtualCardTransaction::class];
            } elseif ($search['type'] == 'Deposit') {
                $morphWith = [Deposit::class => ['sender', 'receiver', 'currency']];
                $whereHasMorph = [Deposit::class];
            } elseif ($search['type'] == 'BillPay') {
                $morphWith = [BillPay::class => ['user', 'baseCurrency']];
                $whereHasMorph = [BillPay::class];
            } elseif ($search['type'] == 'Exchange') {
                $morphWith = [Exchange::class => ['user', 'fromWallet', 'toWallet']];
                $whereHasMorph = [Exchange::class];
            } elseif ($search['type'] == 'CommissionEntry') {
                $morphWith = [CommissionEntry::class => ['sender', 'receiver', 'currency']];
                $whereHasMorph = [CommissionEntry::class];
            }
        } else {
            $morphWith = [
                CommissionEntry::class => ['sender', 'receiver', 'currency'],
                Transfer::class => ['sender', 'receiver', 'currency'],
                RequestMoney::class => ['sender', 'receiver', 'currency'],
                RedeemCode::class => ['sender', 'receiver', 'currency'],
                Escrow::class => ['sender', 'receiver', 'currency'],
                Voucher::class => ['sender', 'receiver', 'currency'],
                Deposit::class => ['sender', 'receiver', 'currency'],
                Exchange::class => ['user', 'fromWallet', 'toWallet'],
                Invoice::class => ['sender', 'currency'],
                QRCode::class => ['user', 'currency'],
                ProductOrder::class => ['user'],
                VirtualCardTransaction::class => ['user', 'currency'],
                BillPay::class => ['user', 'baseCurrency'],
            ];
            $whereHasMorph = [
                CommissionEntry::class,
                Transfer::class,
                RequestMoney::class,
                RedeemCode::class,
                Escrow::class,
                Voucher::class,
                Deposit::class,
                Exchange::class,
                Invoice::class,
                QRCode::class,
                ProductOrder::class,
                VirtualCardTransaction::class,
                BillPay::class,
            ];
        }

        $transactions = Transaction::with(['transactional' => function (MorphTo $morphTo) use ($morphWith, $whereHasMorph) {
            $morphTo->morphWith($morphWith);
        }])
            ->whereHasMorph('transactional', $whereHasMorph, function ($query, $type) use ($search, $created_date, $user) {

                if ($type == CommissionEntry::class) {
                    $query->where(function ($query) use ($user) {
                        $query->where('from_user', '=', $user->id);
                        $query->orWhere('to_user', '=', $user->id);
                    });
                } elseif ($type === Transfer::class || $type === RequestMoney::class || $type === RedeemCode::class || $type === Escrow::class || $type === Voucher::class) {
                    $query->where(function ($query) use ($user) {
                        $query->where('sender_id', '=', $user->id);
                        $query->orWhere('receiver_id', '=', $user->id);
                    });
                } elseif ($type === Deposit::class || $type === Exchange::class || $type === ProductOrder::class || $type === QRCode::class || $type === VirtualCardTransaction::class || $type === BillPay::class) {
                    $query->where('user_id', $user->id);
                } elseif ($type === Invoice::class) {
                    $query->where('sender_id', $user->id);
                }

                $query->when(isset($search['utr']), function ($query) use ($search, $type) {
                    if ($type == Invoice::class) {
                        return $query->where('has_slug', 'LIKE', $search['utr']);
                    } elseif ($type == QRCode::class || $type == VirtualCardTransaction::class) {
                        return $query;
                    } else {
                        return $query->where('trx_id', 'LIKE', $search['utr']);
                    }
                })
                    ->when(isset($search['email']), function ($query) use ($search, $type) {
                        if ($type == Invoice::class) {
                            return $query->where('customer_email', 'LIKE', "%{$search['email']}%");
                        } elseif ($type != CommissionEntry::class && $type != Exchange::class && $type != VirtualCardTransaction::class && $type != BillPay::class) {
                            return $query->where('email', 'LIKE', "%{$search['email']}%");
                        }
                    })
                    ->when(isset($search['min']), function ($query) use ($search) {
                        return $query->where('amount', '>=', $search['min']);
                    })
                    ->when(isset($search['max']), function ($query) use ($search) {
                        return $query->where('amount', '<=', $search['max']);
                    })
                    ->when(isset($search['currency_id']), function ($query) use ($search) {
                        return $query->where('currency_id', $search['currency_id']);
                    })
                    ->when($created_date == 1, function ($query) use ($search) {
                        return $query->whereDate("created_at", $search['created_at']);
                    });
            }
            );

        $data = [
            'user' => $user,
            'transactions' => $transactions,
            'search' => $search,
            'currencies' => $currencies,
        ];
        return $data;
    }


    public function getTransactionHistory(Request $request)
    {
        try {
            $user = auth()->user();

            $query = Transaction::query()
                ->with([
                    'user:id,username,firstname,lastname,image,image_driver',
                    'currency:id,name,code,symbol,exchange_rate,logo,driver'
                ])
                ->where('user_id', $user->id)
                ->latest();

            if ($request->filled('trx_id')) {
                $query->where('trx_id', 'LIKE', '%' . $request->trx_id . '%');
            }

            if ($request->filled('created_at') && preg_match("/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/", $request->created_at)) {
                $query->whereDate('created_at', $request->created_at);
            }

            $transactions = $query->paginate(15);

            $data['transactions'] = $transactions->through(function ($trx) {
                return [
                    'trx_id' => $trx->trx_id,
                    'amount' => getAmount($trx->amount),
                    'charge' => getAmount($trx->charge),
                    'currency' => $trx->currency?->code ?? 'N/A',
                    'trx_type' => $trx->trx_type,
                    'remarks' => $trx->remarks,
                    'created_at' => dateTime($trx->created_at),
                ];
            });

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }


    public function getCommission(Request $request)
    {
        try {
            $userId = Auth::id();
            $search = $request->all();
            $data['commissionEntries'] = CommissionEntry::query()
                ->with(['sender', 'receiver', 'currency'])
                ->filterByUser($userId)
                ->search($search)
                ->latest()
                ->paginate(20)
                ->through(fn($query) => $query->transformData());

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function showKyc()
    {
        try {
            $data['status'] = [
                'pending ' => 0,
                'verified  ' => 1,
                'rejected  ' => 2,
            ];
            $data['kycType'] = auth()->user()->kyc_verified;
            $data['kyc'] = Kyc::first();
            if ($data['kyc']) {
                return response()->json($this->withSuccess($data));
            }
            return response()->json($this->withSuccess('KYC Verification off at this moment'));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function submitKyc(Request $request)
    {
        try {
            $checkKyc = UserKyc::where('user_id', auth()->id())->get();

            foreach ($checkKyc as $kyc) {
                if ($kyc->kyc_id == $request->type) {
                    return response()->json($this->withErrors('KYC has already been submitted.'));
                }
            }
            foreach ($checkKyc as $kyc) {
                if ($kyc->status == 2) {
                    $kyc->delete();
                }
            }
            $kyc = Kyc::where('id', $request->type)->where('status', 1)->first();
            if (!$kyc) {
                return response()->json($this->withErrors('Kyc Not Found'));
            }
            $params = $kyc->input_form;
            $reqData = $request->except('_token', '_method');
            $rules = [];
            if ($params !== null) {
                foreach ($params as $key => $cus) {
                    $rules[$key] = [$cus->validation == 'required' ? $cus->validation : 'nullable'];
                    if ($cus->type === 'file') {
                        $rules[$key][] = 'image';
                        $rules[$key][] = 'mimes:jpeg,jpg,png';
                        $rules[$key][] = 'max:2048';
                    } elseif ($cus->type === 'text') {
                        $rules[$key][] = 'max:191';
                    } elseif ($cus->type === 'number') {
                        $rules[$key][] = 'numeric';
                    } elseif ($cus->type === 'textarea') {
                        $rules[$key][] = 'min:3';
                        $rules[$key][] = 'max:300';
                    }
                }
            }

            $validator = Validator::make($reqData, $rules);
            if ($validator->fails()) {
                return response()->json($this->withErrors(collect($validator->errors())->collapse()));
            }

            $reqField = [];
            foreach ($request->except('_token', '_method', 'type') as $k => $v) {
                foreach ($params as $inKey => $inVal) {
                    if ($k == $inKey) {
                        if ($inVal->type == 'file' && $request->hasFile($inKey)) {
                            try {
                                $file = $this->fileUpload($request[$inKey], config('filelocation.kyc.path'));
                                $reqField[$inKey] = [
                                    'field_name' => $inVal->field_name,
                                    'field_label' => $inVal->field_label,
                                    'field_value' => $file['path'],
                                    'field_driver' => $file['driver'],
                                    'validation' => $inVal->validation,
                                    'type' => $inVal->type,
                                ];
                            } catch (\Exception $exp) {
                                return response()->json($this->withErrors("Could not upload your {$inKey}"));
                            }
                        } else {
                            $reqField[$inKey] = [
                                'field_name' => $inVal->field_name,
                                'field_label' => $inVal->field_label,
                                'validation' => $inVal->validation,
                                'field_value' => $v,
                                'type' => $inVal->type,
                            ];
                        }
                    }
                }
            }
            UserKyc::create([
                'user_id' => auth()->id(),
                'kyc_id' => $kyc->id,
                'kyc_type' => $kyc->name,
                'kyc_info' => $reqField
            ]);

            return response()->json($this->withSuccess("KYC Submitted Successfully"));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function getKyc($id = null)
    {

        $user = auth()->user();
        $data['status'] = [
            'pending ' => 0,
            'verified  ' => 1,
            'rejected  ' => 2,
        ];
        $data['KycList'] = Kyc::query()->where('status', 1)->get()
            ->map(function ($kyc) use ($user) {
                $userKyc = UserKyc::where('kyc_id', $kyc->id)
                    ->where('user_id', $user->id)
                    ->first();
                $kyc->user_kyc_status = $userKyc ? $userKyc->status : null;
                return $kyc;
            });
        try {
            $data['userImage'] = getFile($user->image_driver, $user->image);
            $data['fullName'] = $user->name;
            $data['username'] = $user->username;

            if ($id !== null) {
                $item = Kyc::where('status', 1)->find($id);
                if (!$item) {
                    return response()->json($this->withErrors('Record not found'));
                }
                $userKyc = UserKyc::where('kyc_id', $id)
                    ->where('user_id', $user->id)
                    ->first();
                $formShow = "isFormShow";
                $msg = "msg";

                if ($userKyc) {
                    $type = $userKyc->kyc_type;
                    $status = $userKyc->status;

                    $data = [
                        $formShow => true,
                        $msg => null,
                        'user_kyc_status' => $status,
                        'kycFormData' => $item,
                    ];
                    if ($status == 0) {
                        $data[$formShow] = false;
                        $data[$msg] = "Your {$type} submission has been pending";
                    } elseif ($status == 1) {
                        $data[$formShow] = false;
                        $data[$msg] = "Your {$type} already verified";
                    } elseif ($status == 2) {
                        $data[$msg] = "Your previous {$type} request has been rejected";
                        $data['rejectReason'] = ($userKyc->reason) ? $userKyc->reason : null;
                    }

                } else {
                    $data = [
                        $formShow => true,
                        $msg => null,
                        'kycFormData' => $item,
                    ];
                }
            }

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function notificationSettings()
    {
        try {

            $user = User::with('notifypermission')->findOrFail(auth()->id());
            $role = $user->type;

            $allowed = match ($role) {
                'user' => [1, 2, 5, 6],
                'agent' => [1, 3, 5, 7],
                'merchant' => [1, 4, 6, 7],
                default => [1],
            };

            $notificationTemplates = NotificationTemplate::where('notify_for', 0)
                ->whereIn('type', $allowed)
                ->get()
                ->unique('template_key');

            $statusLabels = [
                '0 = Inactive',
                '1 = Active',
            ];
            $formattedData = $notificationTemplates->map(fn($item) => [
                'id' => $item->id,
                'name' => $item->name,
                'key' => $item->template_key,
                'status' => $item->status,
            ]);

            $data['statusLabels'] = $statusLabels;
            $data['notification'] = $formattedData;
            $data['userHasPermission'] = $user->notifypermission;

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function notificationPermissionStore(Request $request)
    {
        try {
            $user = Auth::user();
            $rules = [
                'email_key' => 'required',
                'sms_key' => 'required',
                'in_app_key' => 'required',
                'push_key' => 'required',
            ];
            $validator = Validator::make($request->all(), $rules);
            if ($validator->fails()) {
                return response()->json($this->withErrors(collect($validator->errors())->collapse()));
            }
            $userTemplate = $user->notifypermission()->first();
            if (!$userTemplate) {
                return response()->json($this->withErrors('Record not found'));
            }
            $default = ['PASSWORD_RESET', 'VERIFICATION_CODE'];
            $mergeWithDefault = function ($keys) use ($default) {
                return array_values(array_unique(array_merge($keys, $default)));
            };
            $userTemplate->template_email_key = $mergeWithDefault($request->email_key);
            $userTemplate->template_sms_key = $mergeWithDefault($request->sms_key);
            $userTemplate->template_in_app_key = $mergeWithDefault($request->in_app_key);
            $userTemplate->template_push_key = $mergeWithDefault($request->push_key);
            $userTemplate->save();

            return response()->json($this->withSuccess('Notification Permission Updated Successfully.'));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function apiKey(Request $request)
    {
        try {
            $user = auth()->user();
            if ($request->method() == 'GET') {
                $public_key = $user->public_key;
                $secret_key = $user->secret_key;
                if (!$public_key || !$secret_key) {
                    $user->public_key = bin2hex(random_bytes(20));
                    $user->secret_key = bin2hex(random_bytes(20));
                    $user->save();
                }
                $data['publicKey'] = $user->public_key;
                $data['secretKey'] = $user->secret_key;
                $data['mode'] = $user->mode == 0 ? 'Test' : 'Live';
                return response()->json($this->withSuccess($data));
            }
            if ($request->method() == 'POST') {
                $twoFactorSetting = TwoFactorSetting::firstOrCreate(['user_id' => $user->id]);
                $purifiedData = Purify::clean($request->all());
                $rules['security_pin'] = 'required|integer|digits:5';
                $validate = Validator::make($request->all(), $rules);
                if ($validate->fails()) {
                    return response()->json($this->withErrors(collect($validate->errors())->collapse()[0]));
                }
                if (!Hash::check($purifiedData['security_pin'], $twoFactorSetting->security_pin)) {
                    return response()->json($this->withErrors('You have entered an incorrect PIN'));
                }

                $user->public_key = bin2hex(random_bytes(20));
                $user->secret_key = bin2hex(random_bytes(20));
                $user->save();
                return response()->json($this->withSuccess('Api key generated successfully'));
            }
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function apiKeyModeChange()
    {
        try {
            $user = auth()->user();
            $user->mode = $user->mode == 0 ? 1 : 0;
            $user->save();
            return response()->json($this->withSuccess('Mode Updated'));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function setting(Request $request)
    {
        try {
            $user = Auth::user();
            if ($request->method() == 'GET') {
                $data['currencies'] = Currency::where('is_active', 1)->orderBy('name', 'asc')->get();
                $data['storeCurrency'] = $user->store_currency_id;
                $data['qrCurrency'] = $user->qr_currency_id;
                return response()->json($this->withSuccess($data));
            }
            if ($request->method() == 'POST') {
                $rules['currency'] = 'required|integer';
                $rules['qr_currency_id'] = 'required|integer';
                $validate = Validator::make($request->all(), $rules);
                if ($validate->fails()) {
                    return response()->json($this->withErrors(collect($validate->errors())->collapse()[0]));
                }
                $user->store_currency_id = $request->currency;
                $user->qr_currency_id = $request->qr_currency_id;
                $user->save();

                return response()->json($this->withSuccess('Updated Successfully'));
            }
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function profile(Request $request)
    {
        try {
            $user = Auth::user();
            $userProfile = User::query()
                ->select('id', 'type', 'username', 'language_id', 'firstname', 'lastname', 'email', 'image_driver', 'image',
                    'qr_link', 'qr_currency_id', 'country', 'state', 'city', 'phone_code', 'phone', 'address_one', 'address_two',
                    'shop_name', 'business_name', 'business_type', 'gst_number', 'pan_number', 'zip_code', 'status', 'created_at',
                    'is_shop_online', 'shop_opening_time', 'shop_closing_time', 'shop_closed_days', 'landmark', 'whatsapp_number', 'shop_description')
                ->where(['id' => $user->id])
                ->first();
            $wallets = Wallet::where('user_id', $user->id)->with('currency')->get()->map(function ($query) {
                $query->logo = getFile($query->currency?->driver, $query->currency?->logo);
                return $query;
            });
            if ($request->isMethod('get')) {
                $data['userProfile'] = $userProfile;
                $data['user'] = $userProfile;
                $data['userProfile']['name'] = $userProfile->name ?? null;
                $data['userProfile']['profile_picture'] = getFile($userProfile->image_driver, $userProfile->image);
                $data['userProfile']['language_id'] = $userProfile->language_id ?? null;
                $data['wallets'] = $wallets;
                $data['languages'] = Language::select('id', 'name')->where('default_status', true)->orderBy('name', 'ASC')->get();
                $data['base_currency'] = basicControl()->base_currency;
                $data['userProfile']['qr_link'] = $userProfile->qr_link ? route('public.qr.Payment', $userProfile->qr_link) : null;

                return response()->json($this->withSuccess($data));
            } elseif ($request->isMethod('post')) {
                $rawInput = $request->all();

                // 1. Name normalization (if name is passed as full name)
                if (!empty($rawInput['name'])) {
                    $nameParts = preg_split('/\s+/', trim((string)$rawInput['name']), 2);
                    if (empty($rawInput['first_name'])) {
                        $rawInput['first_name'] = $nameParts[0] ?? $userProfile->firstname ?? 'Merchant';
                    }
                    if (empty($rawInput['last_name'])) {
                        $rawInput['last_name'] = $nameParts[1] ?? $userProfile->lastname ?? $rawInput['first_name'];
                    }
                }

                // 2. If first_name has space but last_name is empty
                if (!empty($rawInput['first_name']) && empty($rawInput['last_name'])) {
                    $fnParts = preg_split('/\s+/', trim((string)$rawInput['first_name']), 2);
                    if (count($fnParts) > 1) {
                        $rawInput['first_name'] = $fnParts[0];
                        $rawInput['last_name'] = $fnParts[1];
                    } else {
                        $rawInput['last_name'] = $userProfile->lastname ?: $rawInput['first_name'];
                    }
                }

                // 3. Fallbacks from existing profile if updating photo or partial fields
                if (empty($rawInput['first_name'])) $rawInput['first_name'] = $userProfile->firstname ?: 'Merchant';
                if (empty($rawInput['last_name'])) $rawInput['last_name'] = $userProfile->lastname ?: $rawInput['first_name'];
                if (empty($rawInput['username'])) $rawInput['username'] = $userProfile->username ?: ($rawInput['phone'] ?? $rawInput['first_name']);
                if (empty($rawInput['phone'])) $rawInput['phone'] = $userProfile->phone;
                if (empty($rawInput['phone_code'])) $rawInput['phone_code'] = $userProfile->phone_code ?: '91';

                $purifiedData = Purify::clean($rawInput);

                $validator = Validator::make($purifiedData, [
                    'first_name' => 'required|max:100|string',
                    'last_name' => 'nullable|max:100|string',
                    'username' => 'required|string',
                    'language' => 'nullable',
                    'phone_code' => 'nullable|max:32',
                    'phone' => 'nullable|max:32',
                    'address' => 'nullable|max:250',
                    'city' => 'nullable|max:100|string',
                    'state' => 'nullable|max:100|string',
                ]);
                if ($validator->fails()) {
                    return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()), 422);
                }
                $purifiedData = (object)$purifiedData;

                $userProfile->firstname = $purifiedData->first_name;
                $userProfile->lastname = $purifiedData->last_name ?? $userProfile->lastname;
                $userProfile->username = $purifiedData->username;
                if (isset($purifiedData->city)) $userProfile->city = $purifiedData->city;
                if (isset($purifiedData->state)) $userProfile->state = $purifiedData->state;
                if (isset($purifiedData->phone)) $userProfile->phone = $purifiedData->phone;
                if (isset($purifiedData->phone_code)) $userProfile->phone_code = $purifiedData->phone_code;
                if (isset($purifiedData->address)) $userProfile->address_one = $purifiedData->address;
                if (!empty($purifiedData->language)) $userProfile->language_id = $purifiedData->language;

                if (isset($purifiedData->shop_name)) $userProfile->shop_name = $purifiedData->shop_name;
                if (isset($purifiedData->business_name)) $userProfile->business_name = $purifiedData->business_name;
                if (isset($purifiedData->business_type)) $userProfile->business_type = $purifiedData->business_type;
                if (isset($purifiedData->gst_number)) $userProfile->gst_number = $purifiedData->gst_number;
                if (isset($purifiedData->pan_number)) $userProfile->pan_number = $purifiedData->pan_number;
                if (isset($purifiedData->zip_code)) $userProfile->zip_code = $purifiedData->zip_code;

                if (isset($purifiedData->is_shop_online)) $userProfile->is_shop_online = filter_var($purifiedData->is_shop_online, FILTER_VALIDATE_BOOLEAN);
                if (isset($purifiedData->shop_opening_time)) $userProfile->shop_opening_time = $purifiedData->shop_opening_time;
                if (isset($purifiedData->shop_closing_time)) $userProfile->shop_closing_time = $purifiedData->shop_closing_time;
                if (isset($purifiedData->shop_closed_days)) $userProfile->shop_closed_days = $purifiedData->shop_closed_days;
                if (isset($purifiedData->landmark)) $userProfile->landmark = $purifiedData->landmark;
                if (isset($purifiedData->whatsapp_number)) $userProfile->whatsapp_number = $purifiedData->whatsapp_number;
                if (isset($purifiedData->shop_description)) $userProfile->shop_description = $purifiedData->shop_description;

                $photoFile = $request->file('profile_picture') 
                    ?? $request->file('image') 
                    ?? $request->file('photo') 
                    ?? $request->file('avatar');

                if ($photoFile && $photoFile->isValid()) {
                    $image = $this->fileUpload($photoFile, config('filelocation.userProfile.path'),
                        null, null, 'webp', 80, $userProfile->image, $userProfile->image_driver);
                    $userProfile->image_driver = $image['driver'];
                    $userProfile->image = $image['path'];
                }

                $userProfile->save();

                return response()->json([
                    'status' => 'success',
                    'message' => 'Profile Updated Successfully',
                    'data' => [
                        'userProfile' => $userProfile,
                        'profile_picture' => getFile($userProfile->image_driver, $userProfile->image),
                    ],
                ]);
            }
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function updateShopStatus(Request $request)
    {
        try {
            $user = Auth::user();
            $validator = Validator::make($request->all(), [
                'is_shop_online' => 'required',
            ]);
            if ($validator->fails()) {
                return response()->json($this->withErrors(collect($validator->errors())->collapse()->first()), 422);
            }

            $user->is_shop_online = filter_var($request->is_shop_online, FILTER_VALIDATE_BOOLEAN);
            if ($request->filled('shop_opening_time')) {
                $user->shop_opening_time = $request->shop_opening_time;
            }
            if ($request->filled('shop_closing_time')) {
                $user->shop_closing_time = $request->shop_closing_time;
            }
            if ($request->filled('shop_closed_days')) {
                $user->shop_closed_days = $request->shop_closed_days;
            }
            $user->save();

            $statusText = $user->is_shop_online ? 'online (open)' : 'offline (closed)';
            return response()->json([
                'status' => 'success',
                'message' => "Shop is now {$statusText}",
                'data' => [
                    'is_shop_online' => (bool)$user->is_shop_online,
                    'shop_name' => $user->shop_name ?? $user->business_name,
                    'shop_opening_time' => $user->shop_opening_time,
                    'shop_closing_time' => $user->shop_closing_time,
                    'shop_closed_days' => $user->shop_closed_days,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()), 500);
        }
    }

    public function changePassword(Request $request)
    {
        $purifiedData = Purify::clean($request->all());
        $validator = Validator::make($purifiedData, [
            'currentPassword' => 'required|min:5',
            'password' => 'required|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json($this->withErrors(collect($validator->errors())->collapse()[0]));
        }
        $user = Auth::user();
        $purifiedData = (object)$purifiedData;

        if (!Hash::check($purifiedData->currentPassword, $user->password)) {
            return response()->json($this->withErrors('current password did not match'));
        }

        $user->password = bcrypt($purifiedData->password);
        $user->save();
        return response()->json($this->withSuccess('Password changed successfully'));
    }

    public function pusherConfig()
    {
        try {
            $data['apiKey'] = env('PUSHER_APP_KEY');
            $data['cluster'] = env('PUSHER_APP_CLUSTER');
            $data['channel'] = 'user-notification.' . Auth::id();
            $data['event'] = 'UserNotification';

            return response()->json($this->withSuccess($data));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function language(Request $request)
    {
        try {
            if (!$request->id) {
                $data['languages'] = Language::select(['id', 'name', 'short_name'])->where('status', 1)->get();
                return response()->json($this->withSuccess($data));
            }
            $lang = Language::where('status', 1)->find($request->id);
            if (!$lang) {
                return response()->json($this->withErrors('Record not found'));
            }

            $json = file_get_contents(resource_path('lang/') . $lang->short_name . '.json');
            if (empty($json)) {
                return response()->json($this->withErrors('File Not Found.'));
            }

            $json = json_decode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
            return response()->json($this->withSuccess($json));
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }

    public function deleteAccount()
    {
        if (config('demo.IS_DEMO')) {
            return response()->json($this->withErrors("This is DEMO version. You can just explore all the features but can't take any action."));
        }
        try {
            $user = auth()->user();
            if ($user) {
                UserAllRecordDeleteJob::dispatch($user->id);
                $user->delete();
                return response()->json($this->withSuccess('Your account has been deleted successfully.'));
            } else {
                return response()->json($this->withErrors('Invalid user'));
            }
        } catch (\Exception $e) {
            return response()->json($this->withErrors($e->getMessage()));
        }
    }
}
