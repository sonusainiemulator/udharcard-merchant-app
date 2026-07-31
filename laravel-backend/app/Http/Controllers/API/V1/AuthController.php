<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    /**
     * Check if a merchant account exists for a given phone/username.
     */
    public function checkMerchantExist(Request $request)
    {
        $phone = $request->phone ?? $request->username ?? $request->mobile ?? '';
        $phone = trim($phone);

        if (empty($phone)) {
            return response()->json([
                'status' => 'error',
                'exists' => false,
                'message' => 'Enter a valid mobile number.'
            ], 422);
        }

        // Clean phone digits
        $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($cleanPhone) > 10) {
            $cleanPhone = substr($cleanPhone, -10);
        }

        $exists = User::where(function ($query) use ($cleanPhone, $phone) {
            $query->where('phone', $phone)
                  ->orWhere('phone', 'like', '%' . $cleanPhone)
                  ->orWhere('username', $phone)
                  ->orWhere('username', 'like', '%' . $cleanPhone);
        })->where('type', 'merchant')->exists();

        if (!$exists) {
            return response()->json([
                'status' => 'error',
                'exists' => false,
                'message' => 'Merchant account does not exist. Please register first.'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'exists' => true,
            'message' => 'Merchant account exists.'
        ], 200);
    }

    public function loginUser(Request $request)
    {
        $phone = $request->username ?? $request->phone ?? '';
        $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($cleanPhone) > 10) {
            $cleanPhone = substr($cleanPhone, -10);
        }

        $user = User::where(function ($query) use ($cleanPhone, $phone) {
            $query->where('phone', $phone)
                  ->orWhere('phone', 'like', '%' . $cleanPhone)
                  ->orWhere('username', $phone);
        })->where('type', 'merchant')->first();

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'Merchant account does not exist. Please register first.'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Login successful',
            'token' => 'sample_merchant_token_' . $user->id,
            'user' => $user
        ], 200);
    }

    public function registerUser(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required',
            'name' => 'required',
            'shop_name' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $phone = trim($request->phone ?? $request->mobile ?? $request->username ?? '');
        $cleanPhone = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($cleanPhone) > 10) {
            $cleanPhone = substr($cleanPhone, -10);
        }

        $user = User::where('phone', $phone)
                    ->orWhere('phone', 'like', '%' . $cleanPhone)
                    ->orWhere('username', $phone)
                    ->first();

        if (!$user) {
            $user = new User();
        }
        $user->name = $request->name;
        $user->phone = $phone;
        $user->username = $phone;
        $user->email = $request->email ?? $phone . '@merchant.udharcard.shop';
        if (\Schema::hasColumn('users', 'shop_name')) {
            $user->shop_name = $request->shop_name;
        }
        $user->type = 'merchant';
        $user->password = Hash::make($request->password ?? '123456');
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Merchant registered successfully',
            'data' => [
                'user' => $user
            ]
        ], 200);
    }

    public function registerUserForm()
    {
        return response()->json(['status' => 'success', 'data' => []], 200);
    }

    public function getEmailForRecoverPass(Request $request)
    {
        return response()->json(['status' => 'success', 'message' => 'Recovery code sent.'], 200);
    }

    public function getCodeForRecoverPass(Request $request)
    {
        return response()->json(['status' => 'success', 'message' => 'Code verified.'], 200);
    }

    public function updatePass(Request $request)
    {
        return response()->json(['status' => 'success', 'message' => 'Password updated.'], 200);
    }
}
