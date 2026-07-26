<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerController extends Controller
{
    /**
     * Get all customers associated with the logged-in merchant.
     */
    public function index(Request $request)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1; // Fallback for testing

        $customers = Customer::where('merchant_id', $merchantId)
            ->select('id', 'name', 'phone', 'email', 'opening_balance', 'outstanding_balance', 'credit_limit')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'contacts' => $customers
            ]
        ]);
    }

    /**
     * Store a new customer.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:15',
            'email' => 'nullable|email|max:255',
            'credit_limit' => 'nullable|numeric|min:0',
            'opening_balance' => 'nullable|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;

        $openingBal = $request->input('opening_balance', 0.00);

        // Check if customer already exists for this merchant
        $existing = Customer::where('merchant_id', $merchantId)
            ->where('phone', $request->phone)
            ->first();

        if ($existing) {
            return response()->json([
                'status' => 'error',
                'message' => 'A customer with this phone number already exists.'
            ], 400);
        }

        $customer = Customer::create([
            'merchant_id' => $merchantId,
            'name' => $request->name,
            'phone' => $request->phone,
            'email' => $request->email,
            'credit_limit' => $request->input('credit_limit', 5000.00),
            'opening_balance' => $openingBal,
            'outstanding_balance' => $openingBal, // Initial outstanding is opening balance
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Customer created successfully.',
            'data' => $customer
        ], 200);
    }

    /**
     * Update customer credit limit.
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'credit_limit' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;

        $customer = Customer::where('merchant_id', $merchantId)
            ->where('id', $id)
            ->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer not found.'
            ], 404);
        }

        $customer->credit_limit = (float) $request->input('credit_limit');
        $customer->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Customer credit limit updated successfully.',
            'data' => [
                'id' => $customer->id,
                'credit_limit' => (float) $customer->credit_limit,
            ]
        ], 200);
    }

    /**
     * Delete a customer.
     */
    public function destroy(Request $request, $id)
    {
        $merchantId = auth()->id() ?? $request->header('X-Merchant-Id') ?? 1;

        $customer = Customer::where('merchant_id', $merchantId)->where('id', $id)->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Customer not found.'
            ], 404);
        }

        $customer->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Customer account deleted successfully.'
        ], 200);
    }

    /**
     * Get merchant dashboard metrics (mocked/basic wallets and currencies to satisfy client app model)
     */
    public function dashboard(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'message' => [
                'baseCurrency' => 'INR',
                'baseCurrencySymbol' => '₹',
                'wallets' => [
                    [
                        'id' => 1,
                        'uuid' => 'merchant-wallet-main',
                        'currency_code' => 'INR',
                        'balance' => 0.00,
                        'status' => 1,
                        'default' => 1,
                        'currency' => [
                            'id' => 1,
                            'code' => 'INR',
                            'rate' => 1.00
                        ]
                    ]
                ],
                'recipients' => [],
                'currency' => []
            ]
        ]);
    }
}
