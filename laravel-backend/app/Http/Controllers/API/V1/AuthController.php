<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Mail\SendMail;
use App\Models\Currency;
use App\Models\Fund;
use App\Models\Language;
use App\Models\Transaction;
use App\Models\User;
use App\Models\Wallet;
use App\Traits\ApiValidation;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
	use ApiValidation, \App\Traits\Notify;

	public function registerUserForm()
	{
		try {
			$info = json_decode(json_encode(getIpInfo()), true);
			$country_code = null;
			if (!empty($info['code'])) {
				$data['country_code'] = @$info['code'][0];
			}
			$data['countries'] = config('country');
			return response()->json($this->withSuccess($data));
		} catch (\Exception $e) {
			return response()->json($this->withErrors($e));
		}
	}

    /**
     * Check if a phone, username, or email belongs to an Administrator.
     * Admin accounts are strictly prohibited from logging into or registering in the Merchant App.
     */
    protected function isAdminIdentifier(?string $identifier): bool
    {
        if (empty($identifier)) {
            return false;
        }

        $trimmed = trim((string)$identifier);

        // Check if digits match any admin phone in admins table
        $digits = preg_replace('/[^0-9]/', '', $trimmed);
        $last10 = strlen($digits) >= 10 ? substr($digits, -10) : $digits;

        if (!empty($last10)) {
            $adminPhoneExists = \Illuminate\Support\Facades\DB::table('admins')
                ->where(function ($q) use ($trimmed, $digits, $last10) {
                    $q->where('phone', $trimmed)
                        ->orWhere('phone', $digits)
                        ->orWhere('phone', 'like', "%{$last10}")
                        ->orWhere('username', $trimmed)
                        ->orWhere('username', $last10);
                })
                ->exists();

            if ($adminPhoneExists) {
                return true;
            }
        }

        // Check if username or email matches any admin record
        $adminExists = \Illuminate\Support\Facades\DB::table('admins')
            ->where('email', $trimmed)
            ->orWhere('username', $trimmed)
            ->exists();

        return $adminExists;
    }

	public function registerUser(Request $request)
	{
		$basic = basicControl();
		try {
            $data = $request->all();

            $phoneInput = $data['phone'] ?? ($data['username'] ?? null);
            if ($this->isAdminIdentifier($phoneInput) || $this->isAdminIdentifier($data['email'] ?? null) || $this->isAdminIdentifier($data['username'] ?? null)) {
                return response()->json([
                    'status' => 'error',
                    'is_admin' => true,
                    'message' => 'Admin accounts cannot be registered as a Merchant in the Mobile App. Please use the Admin Portal.'
                ], 403);
            }

            if (empty($data['firstname']) && !empty($data['first_name'])) {
                $data['firstname'] = $data['first_name'];
            }
            if (empty($data['lastname']) && !empty($data['last_name'])) {
                $data['lastname'] = $data['last_name'];
            }
            if (empty($data['firstname']) && !empty($data['name'])) {
                $parts = explode(' ', trim($data['name']), 2);
                $data['firstname'] = $parts[0];
                $data['lastname'] = $parts[1] ?? 'Merchant';
            }

            if (!empty($data['phone'])) {
                $data['phone'] = ltrim((string)$data['phone'], '+');
            }

            if (empty($data['phone_code'])) {
                $data['phone_code'] = '91';
            }
            if (empty($data['country'])) {
                $data['country'] = 'India';
            }
            if (empty($data['country_code'])) {
                $data['country_code'] = 'IN';
            }

            if (empty($data['username'])) {
                $baseName = !empty($data['firstname']) ? strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $data['firstname'])) : 'merchant';
                $data['username'] = $baseName . rand(1000, 9999);
                while (User::where('username', $data['username'])->exists()) {
                    $data['username'] = $baseName . rand(10000, 99999);
                }
            }

            if (!empty($data['password']) && empty($data['password_confirmation'])) {
                $data['password_confirmation'] = $data['password'];
            }

            $registerRules = [
                'firstname' => 'required|string|max:255',
                'lastname' => 'required|string|max:255',
                'username' => 'required|string|alpha_dash|min:3|unique:users,username',
                'email' => 'required|string|email|unique:users,email',
                'password' => $basic->strong_password == 0 ?
                    ['required', 'confirmed', 'min:6'] :
                    ['required', 'confirmed', Password::min(6)->mixedCase()
                        ->letters()
                        ->numbers()
                        ->symbols()
                        ->uncompromised()],
                'phone' => ['required', 'string', 'unique:users,phone'],
                'phone_code' => ['required'],
                'country' => ['required'],
                'country_code' => ['required']
            ];

            $message = [
                'password.letters' => 'password must contain letters',
                'password.mixed' => 'password must contain 1 uppercase and lowercase character',
                'password.symbols' => 'password must contain symbols',
            ];

            $validation = Validator::make($data, $registerRules, $message);
            if ($validation->fails()) {
                $firstError = collect($validation->errors()->all())->first() ?? 'Validation failed';
                return response()->json($this->withErrors($firstError));
            }

			if ($request->sponsor != null) {
				$sponsorUser = User::where('username', $request->sponsor)->first();
				$sponsorId = $sponsorUser ? $sponsorUser->id : null;
			} else {
				$sponsorId = null;
			}

			$user = User::create([
                'type' => $data['type'] ?? $request->type ?? 'user',
                'firstname' => $data['firstname'],
                'lastname' => $data['lastname'],
                'username' => $data['username'],
                'email' => $data['email'],
                'password' => Hash::make($data['password']),
                'phone' => $data['phone'],
                'phone_code' => $data['phone_code'],
                'country' => $data['country'],
                'country_code' => $data['country_code'],
                'shop_name' => $data['shop_name'] ?? $data['business_name'] ?? null,
                'business_name' => $data['business_name'] ?? $data['shop_name'] ?? null,
                'business_type' => $data['business_type'] ?? null,
                'gst_number' => $data['gst_number'] ?? null,
                'pan_number' => $data['pan_number'] ?? null,
                'address_one' => $data['address_one'] ?? $data['address'] ?? null,
                'city' => $data['city'] ?? null,
                'state' => $data['state'] ?? null,
                'zip_code' => $data['zip_code'] ?? null,
				'referral_id' => $sponsorId,
				'language_id' => Language::where('default_status', 1)->value('id') ?? 1,
                'email_verification' => 1,
                'sms_verification' => 1,
                'status' => 1,
				'qr_link' => strRandom(20),
			]);

            if ($user->type === 'merchant') {
                \Illuminate\Support\Facades\DB::table('merchant_settings')->insertOrIgnore([
                    'merchant_id' => $user->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                try {
                    $adminMessage = "🔔 *New Merchant Registered!*\n\n"
                        . "👤 *Name:* {$user->firstname} {$user->lastname}\n"
                        . "🏪 *Shop:* " . ($user->shop_name ?? $user->business_name ?? 'N/A') . "\n"
                        . "📱 *Phone:* +{$user->phone_code} {$user->phone}\n"
                        . "📧 *Email:* {$user->email}\n"
                        . "🔑 *Username:* {$user->username}\n"
                        . "📅 *Time:* " . now()->format('d M Y, h:i A');

                    $this->adminWhatsapp(requestMessage: $adminMessage);
                } catch (\Throwable $e) {}
            }

            $user->two_fa_verify = ($user->two_fa == 1) ? 0 : 1;
			$user->save();

			$currencies = Currency::all();
			foreach ($currencies as $currency) {
				Wallet::firstOrCreate(['user_id' => $user->id, 'currency_id' => $currency->id]);
			}

			if ($user && basicControl()->joining_bonus > 0 && basicControl()->signup_bonus_status == 1) {
				$fund = new Fund();
				$fund->user_id = $user->id;
				$fund->currency_id = basicControl()->base_currency;
				$fund->percentage = 0;
				$fund->charge_percentage = 0;
				$fund->charge_fixed = 0;
				$fund->charge = 0;
				$fund->amount = basicControl()->joining_bonus;
				$fund->email = $user->email;
				$fund->status = 1;
				$fund->note = 'Joining bonus';
				$fund->utr = (string)Str::uuid();
				$fund->save();

				updateWallet($fund->user_id, $fund->currency_id, $fund->amount, 1);
				$transaction = new Transaction();
				$transaction->amount = $fund->amount;
				$transaction->charge = $fund->charge;
				$transaction->currency_id = $fund->currency_id;
				$fund->transactional()->save($transaction);
			}

			return response()->json([
				'status' => 'success',
				'message' => 'User Created Successfully',
				'token' => $user->createToken("API TOKEN")->plainTextToken,
				'user' => $user,
				'userProfile' => $user
			]);

		} catch (\Throwable $th) {
			return response()->json($this->withErrors($th->getMessage()));
		}
	}

	public function loginUser(Request $request)
	{
        if ($this->isAdminIdentifier($request->username)) {
            return response()->json([
                'status' => 'error',
                'is_admin' => true,
                'message' => 'This account belongs to an Administrator. Administrator accounts cannot log in to the Merchant App. Please use the Admin Portal.'
            ], 403);
        }

		$validateUser = Validator::make($request->all(),
			[
				'username' => 'required|string',
				'password' => 'required|string',
                'type' => ['required', Rule::in(getAllowedUserTypes())],
            ]);

		if ($validateUser->fails()) {
			return response()->json($this->withErrors(collect($validateUser->errors())->collapse()[0]));
		}
		try {

			$user = User::where('username', $request->username)->first();
			if (!$user) {
				return response()->json($this->withErrors('Invalid username'));
			}

            if ($user->type !== $request->type) {
                return response()->json($this->withErrors("You are not registered as {$request->type}."));
            }

            //User type check
            if (!in_array($user->type, getAllowedUserTypes())) {
                return response()->json($this->withErrors("Login restricted for $user->type."));
            }

            if (!Auth::attempt($request->only(['username', 'password']))) {
                return response()->json($this->withErrors('Invalid username or password.'));
            }

			$user->two_fa_verify = ($user->two_fa == 1) ? 0 : 1;
			$user->save();

            $message = "You’ve been logged in successfully";
			return response()->json([
				'status' => 'success',
				'message' => $message,
				'token' => $user->createToken("API TOKEN")->plainTextToken,
				'user' => $user,
				'userProfile' => $user
			]);

		} catch (\Throwable $th) {
			return response()->json($this->withErrors($th->getMessage()));
		}
	}

	public function getEmailForRecoverPass(Request $request)
	{
        if ($this->isAdminIdentifier($request->email)) {
            return response()->json([
                'status' => 'error',
                'is_admin' => true,
                'message' => 'Admin password recovery is not allowed in the Merchant app. Please use the Admin Portal.'
            ], 403);
        }

		$validateUser = Validator::make($request->all(),
			[
				'email' => 'required|email',
			]);

		if ($validateUser->fails()) {
			return response()->json($this->withErrors(collect($validateUser->errors())->collapse()[0]));
		}

		try {
			$user = User::where('email', $request->email)->first();
			if (!$user) {
				return response()->json($this->withErrors('Email does not exit on record'));
			}

			$code = rand(10000, 99999);
			$data['email'] = $request->email;
			$data['message'] = 'OTP has been send';
			$user->verify_code = $code;
			$user->save();

			$basic = basicControl();
			$message = 'Your Password Recovery Code is ' . $code;
			$email_from = $basic->sender_email;
			@Mail::to($request->email)->send(new SendMail($email_from, "Recovery Code", $message));

			return response()->json($this->withSuccess($data));
		} catch (\Exception $e) {
			return response()->json($this->withErrors($e->getMessage()));
		}
	}

	public function getCodeForRecoverPass(Request $request)
	{
		$validateUser = Validator::make($request->all(),
			[
				'code' => 'required',
				'email' => 'required|email',
			]);

		if ($validateUser->fails()) {
			return response()->json($this->withErrors(collect($validateUser->errors())->collapse()[0]));
		}

		try {
			$user = User::where('email', $request->email)->first();
			if (!$user) {
				return response()->json($this->withErrors('Email does not exit on record'));
			}

			if ($user->verify_code == $request->code && $user->updated_at > Carbon::now()->subMinutes(5)) {
				$user->verify_code = null;
				$user->save();
				return response()->json($this->withSuccess('Code Matching'));
			}

			return response()->json($this->withErrors('Invalid Code'));
		} catch (\Exception $e) {
			return response()->json($this->withErrors($e->getMessage()));
		}
	}

	public function updatePass(Request $request)
	{
		if (config('basic.strong_password') == 0) {
			$rules['password'] = ['required', 'min:6', 'confirmed'];
		} else {
			$rules['password'] = ["required", 'confirmed',
				Password::min(6)->mixedCase()
					->letters()
					->numbers()
					->symbols()
					->uncompromised()];
		}
		$rules['email'] = ['required', 'email'];

		$validateUser = Validator::make($request->all(), $rules);

		if ($validateUser->fails()) {
			return response()->json($this->withErrors(collect($validateUser->errors())->collapse()[0]));
		}

		$user = User::where('email', $request->email)->first();
		if (!$user) {
			return response()->json($this->withErrors('Email does not exist on record'));
		}
		$user->password = Hash::make($request->password);
		$user->save();
		return response()->json($this->withSuccess('Password Updated'));
	}

    public function logout()
    {
        auth()->user()->tokens()->delete();
        return response()->json($this->withSuccess('User is logged out successfully'));
    }

    /**
     * Check if a merchant account exists for a given phone/username.
     */
    public function checkMerchantExist(\Illuminate\Http\Request $request)
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

        // Strictly block Administrator numbers from Merchant App
        if ($this->isAdminIdentifier($phone) || $this->isAdminIdentifier($cleanPhone)) {
            return response()->json([
                'status' => 'error',
                'is_admin' => true,
                'exists' => false,
                'message' => 'This mobile number belongs to an Administrator. Admin accounts cannot log in to the Merchant app. Please use the Admin Portal.'
            ], 403);
        }

        $exists = \App\Models\User::where(function ($query) use ($cleanPhone, $phone) {
            $query->where('phone', $phone)
                  ->orWhere('phone', 'like', '%' . $cleanPhone)
                  ->orWhere('username', $phone)
                  ->orWhere('username', 'like', '%' . $cleanPhone);
        })->where('type', 'merchant')->where('status', 1)->exists();
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


    public function otpLogin(Request $request)
    {
        $validateUser = Validator::make($request->all(), [
            'phone' => 'nullable|string',
            'username' => 'nullable|string',
            'type' => 'nullable|string',
        ]);

        if ($validateUser->fails()) {
            return response()->json($this->withErrors(collect($validateUser->errors())->collapse()->first()), 422);
        }

        try {
            $rawPhone = $request->phone ?: ($request->username ?: $request->mobile);
            $rawPhone = trim((string)$rawPhone);

            if (empty($rawPhone)) {
                return response()->json($this->withErrors('Valid phone number is required.'), 422);
            }

            $cleanPhone = preg_replace('/[^0-9]/', '', $rawPhone);
            $last10 = strlen($cleanPhone) >= 10 ? substr($cleanPhone, -10) : $cleanPhone;
            $type = $request->type ?: 'merchant';

            // Strictly block Administrator numbers from Merchant App OTP Login
            if ($this->isAdminIdentifier($rawPhone) || $this->isAdminIdentifier($cleanPhone) || $this->isAdminIdentifier($last10) || $this->isAdminIdentifier($request->email)) {
                return response()->json([
                    'status' => 'error',
                    'is_admin' => true,
                    'message' => 'This mobile number belongs to an Administrator. Admin accounts cannot log in to the Merchant app. Please use the Admin Portal.'
                ], 403);
            }

            // Find existing user by phone or username
            $user = User::where(function ($query) use ($rawPhone, $cleanPhone, $last10) {
                $query->where('phone', $rawPhone)
                    ->orWhere('phone', $cleanPhone)
                    ->orWhere('phone', 'like', "%{$last10}")
                    ->orWhere('username', $rawPhone)
                    ->orWhere('username', $cleanPhone)
                    ->orWhere('username', 'like', "%{$last10}");
            })->first();

            if (!$user) {
                $username = !empty($last10) ? $last10 : $cleanPhone;
                $email = $request->email ?: "{$username}@merchant.udharcard.shop";
                if (User::where('email', $email)->exists()) {
                    $email = "{$username}_" . time() . "@merchant.udharcard.shop";
                }

                $user = User::create([
                    'type' => $type,
                    'firstname' => $request->firstname ?: ($request->name ?: 'Merchant'),
                    'lastname' => $request->lastname ?: $last10,
                    'username' => $username,
                    'email' => $email,
                    'password' => Hash::make('merchant_default_password'),
                    'phone' => $last10,
                    'phone_code' => '91',
                    'country' => 'India',
                    'country_code' => 'IN',
                    'shop_name' => $request->shop_name ?: ($request->business_name ?: 'My Shop'),
                    'business_name' => $request->business_name ?: ($request->shop_name ?: 'My Shop'),
                    'status' => 1,
                    'sms_verification' => 1,
                    'email_verification' => 1,
                    'two_fa_verify' => 1,
                    'language_id' => Language::where('default_status', 1)->value('id') ?? 1,
                    'qr_link' => strRandom(20),
                ]);

                if ($user->type === 'merchant') {
                    \Illuminate\Support\Facades\DB::table('merchant_settings')->insertOrIgnore([
                        'merchant_id' => $user->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                $currencies = Currency::all();
                foreach ($currencies as $currency) {
                    Wallet::firstOrCreate(['user_id' => $user->id, 'currency_id' => $currency->id]);
                }
            } else {
                $user->status = 1;
                $user->sms_verification = 1;
                $user->email_verification = 1;
                $user->two_fa_verify = 1;
                if ($type && $user->type !== $type) {
                    $user->type = $type;
                }
                if ($request->filled('shop_name') && empty($user->shop_name)) {
                    $user->shop_name = $request->shop_name;
                }
                $user->save();

                if ($user->type === 'merchant') {
                    \Illuminate\Support\Facades\DB::table('merchant_settings')->insertOrIgnore([
                        'merchant_id' => $user->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                $currencies = Currency::all();
                foreach ($currencies as $currency) {
                    Wallet::firstOrCreate(['user_id' => $user->id, 'currency_id' => $currency->id]);
                }
            }

            $token = $user->createToken("merchant-auth")->plainTextToken;

            return response()->json([
                'status' => 'success',
                'message' => 'Merchant authenticated successfully',
                'token' => $token,
                'user' => $user,
                'userProfile' => $user,
            ], 200);
        } catch (\Throwable $th) {
            return response()->json($this->withErrors($th->getMessage()), 500);
        }
    }
}
