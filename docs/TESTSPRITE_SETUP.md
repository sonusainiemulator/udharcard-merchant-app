# TestSprite Setup For Merchant App

This project does not currently include TestSprite configuration. Use this guide to start with a narrow smoke suite that validates merchant registration compatibility with the production or staging backend.

## Scope

Start with these checks:

1. Merchant registration creates a merchant account that is recognized by the backend.
2. Merchant existence check returns `exists: true` after registration.
3. Merchant login succeeds with the registered mobile number and password.

## Why This Matters

The app login flow checks merchant existence before sending OTP. If registration creates a generic user instead of a merchant account, OTP login is blocked even though `/api/register` returned success.

## Backend Contract Required By Current App

The app must send registration data with merchant-specific fields:

- `firstname`
- `lastname`
- `phone`
- `mobile`
- `username`
- `shop_name`
- `business_name`
- `email`
- `password`
- `password_confirmation`
- `phone_code`
- `country`
- `country_code`
- `type=merchant`

Requests must use `Content-Type: application/x-www-form-urlencoded`.

## Recommended TestSprite Assets

Create two suites.

### 1. API Smoke Suite

Use [testsprite/merchant-registration-smoke.json](../testsprite/merchant-registration-smoke.json) as the starting point.

Environment variables to define in TestSprite:

- `BASE_URL`
- `TEST_MERCHANT_PHONE`
- `TEST_MERCHANT_EMAIL`
- `TEST_MERCHANT_NAME`
- `TEST_MERCHANT_SHOP`
- `TEST_MERCHANT_PASSWORD`

### 2. Mobile E2E Smoke Suite

First scenario:

1. Open register screen.
2. Enter merchant full name.
3. Enter phone number.
4. Enter shop name.
5. Enter password.
6. Submit registration.
7. Confirm app routes to login or OTP flow.
8. Validate backend `check-exist` returns success for the same number.

## Suggested Execution Order

1. Run API smoke suite against staging or production test tenant.
2. Only after API suite passes, run mobile registration flow.
3. Add OTP flow coverage later with Firebase test infrastructure or controlled test numbers.

## Current Known Risks

1. Widget tests in this repo are stale and currently fail because expected UI text no longer matches rendered auth screens.
2. Laravel backend folder in this workspace does not currently expose an automated test harness.
3. Production smoke tests create real test merchants, so use disposable phone numbers and emails.

## CLI Smoke Commands

PowerShell example:

```powershell
$base='https://pay.udharcard.shop/api'
$phone='9651033828'

curl.exe -X POST "$base/register" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  --data "name=CLI Merchant Full&firstname=CLI&lastname=Merchant&phone=$phone&mobile=$phone&username=$phone&shop_name=CLI Shop $phone&business_name=CLI Shop $phone&email=rich.$phone@example.com&password=merchant_default_password&password_confirmation=merchant_default_password&phone_code=%2B91&country=India&country_code=IN&type=merchant"

curl.exe -X POST "$base/merchant/check-exist" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  --data "phone=$phone&mobile=$phone&username=$phone&type=merchant"

curl.exe -X POST "$base/login" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  --data "username=$phone&password=merchant_default_password&type=merchant"
```

## Next Expansion

After the smoke suite is stable, add:

1. Login pre-OTP guard validation.
2. Customer add flow.
3. Ledger transaction flow.
4. Payment webhook reconciliation flow.