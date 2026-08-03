<?php

use App\Http\Controllers\ApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\PayoutLogController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\FundController;
use App\Http\Controllers\Api\V1\SendMoneyController;
use App\Http\Controllers\Api\V1\HomeController;
use App\Http\Controllers\Api\V1\RequestMoneyController;
use App\Http\Controllers\Api\V1\ExchangeController;
use App\Http\Controllers\Api\V1\RedeemController;
use App\Http\Controllers\Api\V1\EscrowController;
use App\Http\Controllers\Api\V1\DisputeController;
use App\Http\Controllers\Api\V1\VirtualCardController as UserVirtualCardController;
use App\Http\Controllers\Api\V1\VoucherController;
use App\Http\Controllers\Api\V1\InvoiceController;
use App\Http\Controllers\Api\V1\BillController;
use App\Http\Controllers\Api\V1\SupportTicketController;
use App\Http\Controllers\Api\V1\TwoFASecurityController;
use App\Http\Controllers\Api\V1\PayoutController;
use App\Http\Controllers\Api\V1\VerificationController;
use App\Http\Controllers\Api\V1\SubscriptionController;
use App\Http\Controllers\Api\V1\SubscriptionPaymentController;
use App\Http\Controllers\API\CustomerController;
use App\Http\Controllers\API\PaymentGatewayController;
use App\Http\Controllers\API\UdharLedgerController;
use App\Http\Controllers\API\WorkListController as ApiWorkListController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/


Route::match(['get', 'post'], 'payment/{code}/{trx?}/{type?}', [PaymentController::class, 'gatewayIpn'])->name('ipn');
Route::post('payout/{code}', [PayoutLogController::class, 'payoutIpn'])->name('payout');

Route::post('initiate/payment', [ApiController::class, 'store'])->name('payment.initiate');
Route::post('verify/payment', [ApiController::class, 'verifyPayment'])->name('payment.verify');
Route::get('/subscription/plans', [SubscriptionController::class, 'plans']);
Route::post('/webhook/subscription/razorpay', [SubscriptionPaymentController::class, 'razorpayWebhook']);
Route::post('/merchant/udhar/webhook/razorpay', [PaymentGatewayController::class, 'handleWebhook']);


//Restful Api
Route::controller(AuthController::class)->group(function () {
    Route::get('/register/form', 'registerUserForm');
    Route::post('/register', 'registerUser');
    Route::post('/login', 'loginUser');
    Route::post('/merchant/check-exist', 'checkMerchantExist');
    Route::post('/recovery-pass/get-email', 'getEmailForRecoverPass');
    Route::post('/recovery-pass/get-code', 'getCodeForRecoverPass');
    Route::post('/update-pass', 'updatePass');
});

Route::get('/basic', [HomeController::class, 'basic']);

Route::middleware(['auth:sanctum'])->group(function () {

    Route::middleware('userCheckApi')->group(function () {

        Route::controller(HomeController::class)->group(function () {
            Route::get('/dashboard', 'dashboard');
            Route::get('/get-charge-limit', 'getChargeLimit');
            Route::get('/get/qr-payment', 'getQrPaymentList');
            Route::get('/transaction', 'getTransaction');
            Route::get('/transaction/search', 'getTransactionSearch');
            Route::get('/transaction-history', 'getTransactionHistory');
            Route::get('/commission', 'getCommission');
            Route::get('/commission/search', 'getCommissionSearch');
            Route::get('/kyc/show', 'showKyc');
            Route::post('/kyc/submit', 'submitKyc');
            Route::get('/kyc/list/{id?}', 'getKyc');
            Route::any('/api/key', 'apiKey');
            Route::post('/api/key/mode-change', 'apiKeyModeChange');
            Route::any('/setting', 'setting');
            Route::any('/profile', 'profile');
            Route::post('/change-password', 'changePassword');
            Route::get('/pusher/config', 'pusherConfig');
            Route::get('/language', 'language');
            Route::post('/delete-account', 'deleteAccount');
        });
        Route::get('notification-settings', [HomeController::class, 'notificationSettings']);
        Route::post('notification-permission', [HomeController::class, 'notificationPermissionStore']);

        Route::get('/fund/gateway/currency', [FundController::class, 'fundGatewayCurrencyList']);
        Route::middleware(['userType:user,agent'])->controller(FundController::class)->group(function () {
            Route::get('/fund/list', 'fundList');

            Route::post('/fund-add', 'fundAdd');
            Route::post('automation/payment', 'automationPayment');
            Route::post('card/payment', 'cardPayment');
            Route::post('payment-done', 'paymentDone');
            Route::post('manual-payment/{trx_id}', 'fromSubmit');
        });

        Route::controller(PayoutController::class)->group(function () {
            Route::get('/payout', 'payout');
            Route::post('/payout-submit', 'payoutRequest');
            Route::get('/payout/confirm/preview/{utr}', 'payoutConfirmPreview');
            Route::post('/payout/confirm/submit', 'payoutConfirmSubmit');
            Route::post('/payout/confirm/submit/flutterwave', 'payoutConfirmSubmitFlutter');
            Route::post('/payout/confirm/submit/paystack', 'payoutConfirmSubmitPaystack');
            Route::post('/payout/get-bank/list', 'payoutGetBankList');
            Route::post('/payout/get-bank/from', 'payoutGetBankFrom');
            Route::get('/payout-list', 'payoutList');
        });

        Route::controller(SupportTicketController::class)->group(function () {
            Route::get('/support-ticket/list', 'ticketList');
            Route::post('/support-ticket/create', 'ticketCreate');
            Route::get('/support-ticket/view/{id}', 'ticketView');
            Route::post('/support-ticket/download/{id}', 'ticketDownlaod')->name('api.ticket.download');
            Route::post('/support-ticket/reply', 'ticketReply');
        });

        Route::controller(TwoFASecurityController::class)->group(function () {
            Route::get('/2FA-security', 'twoFASecurity');
            Route::post('/2FA-security/enable', 'twoFASecurityEnable');
            Route::post('/2FA-security/disable', 'twoFASecurityDisable');
            Route::get('/security-pin/create', 'create')->name('create');
            Route::post('/security-pin/store', 'store');
            Route::any('/security-pin/reset', 'reset')->name('reset');
            Route::any('/security-pin/manage', 'manage');
        });

        Route::post('transfer/check-recipient', [SendMoneyController::class,'checkRecipientApi']);

        Route::controller(SubscriptionController::class)->prefix('merchant/subscription')->group(function () {
            Route::get('/current', 'current');
            Route::get('/history', 'paymentHistory');
            Route::post('/checkout', 'createCheckout');
            Route::post('/verify', 'verifyCheckout');
            Route::post('/cancel-auto-renew', 'cancelAutoRenew');
        });

        Route::controller(ApiWorkListController::class)->prefix('merchant/work-list')->group(function () {
            Route::get('/', 'index');
            Route::post('/', 'store');
            Route::put('/{id}', 'update');
            Route::delete('/{id}', 'destroy');
            Route::get('/sync', 'pullSync');
            Route::post('/sync', 'pushSync');
        });

        Route::get('/merchant/udhar/contacts', [CustomerController::class, 'index']);
        Route::post('/merchant/udhar/customers', [CustomerController::class, 'store']);
        Route::put('/merchant/udhar/customers/{id}/credit-limit', [CustomerController::class, 'update']);
        Route::delete('/merchant/udhar/customers/{id}', [CustomerController::class, 'destroy']);
        Route::get('/merchant/udhar/customers/{customerId}/ledger', [UdharLedgerController::class, 'show']);
        Route::post('/merchant/udhar/ledger', [UdharLedgerController::class, 'store']);
        Route::post('/merchant/udhar/qr/generate', [PaymentGatewayController::class, 'generateQr']);
        Route::get('/merchant/udhar/reports', [UdharLedgerController::class, 'reports']);

    });

    Route::middleware(['userCheckApi','userType:user'])->group(function () {

        Route::controller(\App\Http\Controllers\Api\V1\CustomerUdharController::class)->prefix('customer/udhar')->group(function () {
            Route::get('/merchants', 'merchantsList');
            Route::get('/ledger/{merchant_id}', 'ledgerList');
            Route::post('/ledger/verify/{ledger_id}', 'verifyLedgerEntry');
        });

        Route::controller(SendMoneyController::class)->group(function () {
            Route::get('/send/money/list', 'sendMoneyList');
            Route::get('/send/money', 'sendMoney');
            Route::post('/send/money/submit', 'sendMoneySubmit');
            Route::get('/send/money/preview/{utr}', 'sendMoneyPreview');
            Route::post('/send/money/confirm', 'sendMoneyConfirm');
        });

        Route::controller(RequestMoneyController::class)->group(function () {
            Route::get('/request/money/list', 'requestMoneyList');
            Route::get('/request/money', 'requestMoney');
            Route::post('/request/money/submit', 'requestMoneySubmit');
            Route::post('/request/money/cancel', 'requestMoneyCancel');
            Route::get('/request/money/check/{utr}', 'requestMoneyCheck');
            Route::post('/request/money/check/submit', 'requestMoneyCheckSubmit');
            Route::get('/request/money/preview/{utr}', 'requestMoneyPreview');
            Route::post('/request/money/confirm', 'requestMoneyConfirm');
        });

        Route::controller(ExchangeController::class)->group(function () {
            Route::get('/exchange/money', 'exchangeMoney');
            Route::post('/exchange/money/submit', 'exchangeMoneySubmit');
            Route::get('/exchange/money/preview/{utr}', 'exchangeMoneyPreview');
            Route::post('/exchange/money/preview/confirm', 'exchangeMoneyPreviewConfirm');
            Route::get('/exchange/money/list', 'exchangeMoneyList');
        });

        Route::controller(RedeemController::class)->group(function () {
            Route::get('/redeem/generate-code', 'redeemGenerateCode');
            Route::post('/redeem/check-amount', 'redeemCheckAmount');
            Route::post('/redeem/generate-code/submit', 'redeemGenerateCodeSubmit');
            Route::get('/redeem/generate-code/preview/{utr}', 'redeemPreview');
            Route::post('/redeem/generate-code/preview/confirm', 'redeemPreviewConfirm');
            Route::get('/redeem/generate-code/list', 'redeemList');
            Route::post('/redeem/insert', 'redeemInsert');
        });

        Route::controller(EscrowController::class)->group(function () {
            Route::get('/escrow', 'escrow');
            Route::post('/escrow/submit', 'escrowSubmit');
            Route::get('/escrow/preview/{utr}', 'escrowPreview')->name("api.escrowPreview");
            Route::post('/escrow/preview/confirm', 'escrowPreviewConfirm');
            Route::post('/escrow/payment/submit', 'escrowPaymentSubmit');
            Route::get('/escrow/list', 'escrowlist');
            Route::get('/escrow/list/search', 'escrowSearch');
        });

        Route::controller(DisputeController::class)->group(function () {
            Route::get('/dispute', 'dispute')->name('api.dispute');
            Route::post('/dispute/submit', 'disputeSubmit');
            Route::get('/dispute/list', 'disputeList');
            Route::get('/dispute/list/search', 'disputeListSearch');
        });

        Route::controller(UserVirtualCardController::class)->group(function () {
            Route::get('/virtual-card/list', 'virtualCardList');
            Route::get('/virtual-card/order', 'virtualCardOrder');
            Route::post('/virtual-card/order/submit', 'virtualCardOrderSubmit');
            Route::get('/virtual-card/re-submit', 'virtualCardReSubmit');
            Route::post('/virtual-card/re-submit/post', 'virtualCardReSubmitPost');
            Route::post('/virtual-card/block', 'virtualCardBlock');
            Route::get('/virtual-card/transaction', 'virtualCardTran');
        });

        Route::controller(VoucherController::class)->group(function () {
            Route::get('/voucher/list', 'voucherList');
            Route::get('/voucher/list/search', 'voucherListSearch');
            Route::get('/voucher', 'voucher');
            Route::post('/voucher/submit', 'voucherSubmit');
            Route::get('/voucher/preview/{utr}', 'voucherPreview');
            Route::post('/voucher/preview/submit', 'voucherPreviewSubmit');
            Route::post('/voucher/payment/submit', 'voucherPaymentSubmit');
        });

        Route::controller(InvoiceController::class)->group(function () {
            Route::get('/invoice/create', 'invoiceCreate');
            Route::post('/invoice/store', 'invoiceStore');
            Route::get('/invoice/list', 'invoiceList');
            Route::get('/invoice/view/{id}', 'invoiceView');
            Route::post('/invoice/reminder', 'invoiceReminder');
        });

        Route::controller(BillController::class)->group(function () {
            Route::get('/pay-bill', 'payBill');
            Route::post('/pay-bill/submit', 'payBillSubmit');
            Route::get('/pay-bill/preview/{utr}', 'payBillPreview');
            Route::post('/pay-bill/preview/submit', 'payBillPreviewSubmit');
            Route::get('/pay-bill/list', 'payBillList');
        });

        Route::controller(\App\Http\Controllers\Api\V1\StoreController::class)->group(function () {
            Route::group(['prefix' => 'category'], function () {
                Route::get('/', 'category');
                Route::post('store', 'categoryStore');
                Route::get('edit/{id}', 'categoryEdit');
                Route::post('update/{id}', 'categoryUpdate');
                Route::delete('delete/{id}', 'categoryDelete');
            });

            Route::group(['prefix' => 'store'], function () {
                Route::get('/', 'storeList');
                Route::post('create', 'createStore');
                Route::get('edit/{id}', 'editStore');
                Route::post('update/{id}', 'updateStore');
                Route::delete('delete/{id}', 'deleteStore');
            });

            Route::group(['prefix' => 'product/attribute'], function () {
                Route::get('/', 'productAttribute');
                Route::post('store', 'storeAttribute');
                Route::get('edit/{id}', 'editAttribute');
                Route::post('update/{id}', 'updateAttribute');
                Route::delete('delete/{id}', 'deleteAttribute');
            });
        });

    });

    Route::controller(VerificationController::class)->group(function () {
        Route::post('/twoFA-Verify', 'twoFAverify');
        Route::post('/mail-verify', 'mailVerify');
        Route::post('/sms-verify', 'smsVerify');
        Route::get('/resend-code', 'resendCode');
    });
    
    // Udhar Card Merchant Reminder
    Route::post('/merchant/udhar/customers/{id}/remind', [PaymentGatewayController::class, 'sendAppReminder']);
    
});