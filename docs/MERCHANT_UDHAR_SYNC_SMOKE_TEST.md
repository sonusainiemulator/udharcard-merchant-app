# Merchant Udhar Sync Smoke Test

This smoke test validates the full merchant flow:

1. Merchant creates customer.
2. Merchant creates udhar entry.
3. Merchant ledger shows the transaction.
4. Customer app APIs can see merchant and ledger (when a customer token is provided).
5. Legacy ledger endpoint support is probed for compatibility.

## Prerequisites

- Backend API is reachable.
- Merchant auth token (recommended) or fallback merchant id.
- Customer auth token (optional, but required for end-to-end customer app verification).

## Run

Manual QA checklist mode (no token, no credentials):

```powershell
./scripts/merchant_udhar_sync_smoke.ps1 -ManualChecklist
```

Optional custom report output path:

```powershell
./scripts/merchant_udhar_sync_smoke.ps1 -ManualChecklist -ChecklistReportPath "docs/manual_qa_report_today.md"
```

This mode asks y/n for each app flow checkpoint and generates a markdown report with PASS/FAIL summary.

From project root:

```powershell
./scripts/merchant_udhar_sync_smoke.ps1 \
  -BaseUrl "https://pay.udharcard.shop/api" \
  -MerchantToken "<merchant_token>" \
  -CustomerToken "<customer_token>" \
  -MerchantId 1 \
  -Amount 123.45
```

If you do not have tokens, run with credentials and script will auto-login and fetch token:

```powershell
./scripts/merchant_udhar_sync_smoke.ps1 \
  -BaseUrl "https://pay.udharcard.shop/api" \
  -MerchantMobile "<merchant_mobile_number>" \
  -MerchantUsername "<merchant_phone_or_username>" \
  -MerchantPassword "<merchant_password>" \
  -CustomerMobile "<customer_mobile_number>" \
  -CustomerUsername "<customer_phone_or_username>" \
  -CustomerPassword "<customer_password>" \
  -MerchantId 1 \
  -Amount 123.45
```

Mobile-only merchant run (no username, no token):

```powershell
./scripts/merchant_udhar_sync_smoke.ps1 \
  -BaseUrl "https://pay.udharcard.shop/api" \
  -MerchantMobile "<merchant_mobile_number>" \
  -MerchantId 1 \
  -Amount 123.45
```

Note: For merchant login attempts, script automatically tries `merchant_default_password` when no password is provided (matching Firebase onboarding backend registration behavior in current app code).

Merchant-only validation without customer login:

```powershell
./scripts/merchant_udhar_sync_smoke.ps1 \
  -BaseUrl "https://pay.udharcard.shop/api" \
  -MerchantUsername "<merchant_phone_or_username>" \
  -MerchantPassword "<merchant_password>" \
  -MerchantId 1 \
  -Amount 123.45
```

If merchant token and merchant credentials are both not set, the script sends X-Merchant-Id fallback for local/dev environments only.

## Expected output

- Script prints progress [1/6] to [6/6].
- Summary includes:
  - Customer ID
  - Legacy ledger route state: supported, fallback_only, or error status
  - Merchant ledger transactions count
  - Customer sync state
- Final line should be PASS.

## Notes

- The script creates a unique test customer using timestamp-based phone and name.
- If CustomerToken is omitted, customer-app sync checks are skipped and only merchant-path checks run.
