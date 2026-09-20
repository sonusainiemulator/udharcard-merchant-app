<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification.
     *
     * @var array<int, string>
     */
    protected $except = [
        '*save-token*',
        '*sort-payment-methods*',
        '*admin/upload/ck/image*',
        '*store/product/checkout/store*',
        '*store/product/order/stage/change*',
        '*payout-bank-form*',
        '*payout-bank-list*',
        '*api/add-service*',
        '*pay-bill/fetch-services*',
        '*/save-token*',
        '*fetch/operators*',
        '*fetch/balance*',
        '*fetch-services*',
        '*fetch-amount*',
        "*payment*",
        '*passkey/login-verify*'
    ];
}
