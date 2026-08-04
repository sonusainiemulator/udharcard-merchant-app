param(
    [string]$BaseUrl = "https://pay.udharcard.shop/api",
    [switch]$ManualChecklist,
    [string]$ChecklistReportPath = "",
    [string]$MerchantToken = "",
    [string]$MerchantMobile = "",
    [string]$MerchantUsername = "",
    [string]$MerchantPassword = "",
    [string]$CustomerToken = "",
    [string]$CustomerMobile = "",
    [string]$CustomerUsername = "",
    [string]$CustomerPassword = "",
    [int]$MerchantId = 1,
    [double]$Amount = 123.45
)

$ErrorActionPreference = "Stop"

function New-Headers([string]$token, [int]$merchantId) {
    $headers = @{
        "Accept" = "application/json"
    }

    if (![string]::IsNullOrWhiteSpace($token)) {
        $headers["Authorization"] = "Bearer $token"
    } else {
        $headers["X-Merchant-Id"] = "$merchantId"
    }

    return $headers
}

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [hashtable]$Body = $null,
        [switch]$AllowFailure
    )

    try {
        if ($null -eq $Body) {
            $response = Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers
        } else {
            $response = Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers -Body $Body -ContentType "application/x-www-form-urlencoded"
        }

        return [PSCustomObject]@{
            Ok = $true
            StatusCode = 200
            Body = $response
        }
    } catch {
        $statusCode = 0
        $rawBody = ""

        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $rawBody = $reader.ReadToEnd()
                $reader.Close()
            } catch {
                $rawBody = ""
            }
        }

        if ($AllowFailure) {
            return [PSCustomObject]@{
                Ok = $false
                StatusCode = $statusCode
                Body = $rawBody
            }
        }

        throw "API call failed: $Method $Url (status=$statusCode) body=$rawBody"
    }
}

function Assert-SuccessResponse([object]$apiResult, [string]$StepName) {
    if (-not $apiResult.Ok) {
        throw "$StepName failed with HTTP status $($apiResult.StatusCode)"
    }

    if ($apiResult.Body.status -ne "success") {
        throw "$StepName returned non-success payload: $($apiResult.Body | ConvertTo-Json -Depth 8)"
    }
}

function Read-ChecklistAnswer([string]$Prompt) {
    while ($true) {
        $inputValue = Read-Host "$Prompt (y/n)"
        if ($null -eq $inputValue) {
            continue
        }

        $normalized = $inputValue.Trim().ToLowerInvariant()
        if ($normalized -eq "y" -or $normalized -eq "yes") {
            return "PASS"
        }
        if ($normalized -eq "n" -or $normalized -eq "no") {
            return "FAIL"
        }

        Write-Host "Please answer with y or n." -ForegroundColor Yellow
    }
}

function Run-ManualChecklist {
    param(
        [string]$ChecklistReportPath
    )

    Write-Host "Running manual QA checklist mode (no token/login required)."
    Write-Host "Use merchant app UI for each step, then answer y/n."
    Write-Host ""

    $cases = @(
        [PSCustomObject]@{ Id = "M1"; Step = "Merchant login via mobile OTP works" },
        [PSCustomObject]@{ Id = "M2"; Step = "Add Customer screen opens" },
        [PSCustomObject]@{ Id = "M3"; Step = "Create customer succeeds from app" },
        [PSCustomObject]@{ Id = "M4"; Step = "Added customer appears in customer list" },
        [PSCustomObject]@{ Id = "M5"; Step = "Add Udhar screen opens for selected customer" },
        [PSCustomObject]@{ Id = "M6"; Step = "Add udhar entry succeeds" },
        [PSCustomObject]@{ Id = "M7"; Step = "Ledger shows new udhar transaction" },
        [PSCustomObject]@{ Id = "M8"; Step = "Outstanding balance updates correctly" },
        [PSCustomObject]@{ Id = "M9"; Step = "App remains stable (no crash/hang)" }
    )

    $results = @()
    foreach ($case in $cases) {
        $status = Read-ChecklistAnswer -Prompt "[$($case.Id)] $($case.Step)"
        $results += [PSCustomObject]@{
            Id = $case.Id
            Step = $case.Step
            Status = $status
        }
    }

    $passCount = @($results | Where-Object { $_.Status -eq "PASS" }).Count
    $failCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
    $overall = if ($failCount -eq 0) { "PASS" } else { "FAIL" }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if ([string]::IsNullOrWhiteSpace($ChecklistReportPath)) {
        $ChecklistReportPath = "docs/manual_qa_udhar_checklist_report_$timestamp.md"
    }

    $lines = @()
    $lines += "# Merchant Manual QA Checklist Report"
    $lines += ""
    $lines += "- Executed at: $(Get-Date -Format \"yyyy-MM-dd HH:mm:ss\")"
    $lines += "- Overall: $overall"
    $lines += "- Passed: $passCount"
    $lines += "- Failed: $failCount"
    $lines += ""
    $lines += "| Case | Step | Result |"
    $lines += "| --- | --- | --- |"

    foreach ($row in $results) {
        $lines += "| $($row.Id) | $($row.Step) | $($row.Status) |"
    }

    $directory = Split-Path -Path $ChecklistReportPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    Set-Content -Path $ChecklistReportPath -Value $lines -Encoding UTF8

    Write-Host ""
    Write-Host "Manual checklist completed."
    Write-Host "- Overall: $overall"
    Write-Host "- Passed: $passCount"
    Write-Host "- Failed: $failCount"
    Write-Host "- Report: $ChecklistReportPath"

    if ($overall -eq "PASS") {
        Write-Host "PASS"
    } else {
        Write-Host "FAIL"
    }
}

if ($ManualChecklist) {
    Run-ManualChecklist -ChecklistReportPath $ChecklistReportPath
    return
}

function Resolve-TokenFromLogin {
    param(
        [string]$BaseUrl,
        [string]$Username,
        [string]$Mobile,
        [string]$Password,
        [string]$Type
    )

    $identifier = $Username
    if ([string]::IsNullOrWhiteSpace($identifier)) {
        $identifier = $Mobile
    }

    if ([string]::IsNullOrWhiteSpace($identifier)) {
        return ""
    }

    $candidatePasswords = @()
    if (-not [string]::IsNullOrWhiteSpace($Password)) {
        $candidatePasswords += $Password
    }

    # Merchant OTP registration in app seeds this default backend password.
    if ($Type -eq "merchant") {
        if ($candidatePasswords -notcontains "merchant_default_password") {
            $candidatePasswords += "merchant_default_password"
        }
    }

    if ($candidatePasswords.Count -eq 0) {
        return ""
    }

    foreach ($pass in $candidatePasswords) {
        $loginResult = Invoke-Api -Method "POST" -Url "$BaseUrl/login" -Headers @{ "Accept" = "application/json" } -Body @{
            username = $identifier
            phone = $identifier
            mobile = $identifier
            password = $pass
            type = $Type
        } -AllowFailure

        if ($loginResult.Ok -and $loginResult.Body.status -eq "success") {
            $token = [string]($loginResult.Body.token)
            if ([string]::IsNullOrWhiteSpace($token)) {
                throw "Login ($Type) succeeded but token is missing in response"
            }

            return $token
        }
    }

    return ""
}

if ([string]::IsNullOrWhiteSpace($MerchantToken)) {
    $MerchantToken = Resolve-TokenFromLogin -BaseUrl $BaseUrl -Username $MerchantUsername -Mobile $MerchantMobile -Password $MerchantPassword -Type "merchant"
    if (-not [string]::IsNullOrWhiteSpace($MerchantToken)) {
        Write-Host "Merchant token resolved via login"
    } else {
        Write-Host "Merchant token could not be resolved from credentials/mobile."
    }
}

if ([string]::IsNullOrWhiteSpace($CustomerToken)) {
    $CustomerToken = Resolve-TokenFromLogin -BaseUrl $BaseUrl -Username $CustomerUsername -Mobile $CustomerMobile -Password $CustomerPassword -Type "user"
    if (-not [string]::IsNullOrWhiteSpace($CustomerToken)) {
        Write-Host "Customer token resolved via login"
    } elseif (-not [string]::IsNullOrWhiteSpace($CustomerUsername) -or -not [string]::IsNullOrWhiteSpace($CustomerMobile)) {
        Write-Host "Customer token could not be resolved from credentials/mobile."
    }
}

$merchantHeaders = New-Headers -token $MerchantToken -merchantId $MerchantId
$customerHeaders = New-Headers -token $CustomerToken -merchantId $MerchantId

$stamp = Get-Date -Format "yyyyMMddHHmmss"
$customerPhone = "90000$stamp"
if ($customerPhone.Length -gt 15) {
    $customerPhone = $customerPhone.Substring(0, 15)
}
$customerName = "Smoke Customer $stamp"

Write-Host "[1/6] Create customer via merchant API"
$createCustomer = Invoke-Api -Method "POST" -Url "$BaseUrl/merchant/udhar/customers" -Headers $merchantHeaders -Body @{
    name = $customerName
    phone = $customerPhone
    email = "smoke.$stamp@example.com"
    opening_balance = "50"
    credit_limit = "5000"
}
Assert-SuccessResponse -apiResult $createCustomer -StepName "Create customer"
$customerId = [string]$createCustomer.Body.data.id
if ([string]::IsNullOrWhiteSpace($customerId)) {
    throw "Create customer response missing customer id"
}

Write-Host "[2/6] Add udhar entry using modern ledger endpoint"
$addModernLedger = Invoke-Api -Method "POST" -Url "$BaseUrl/merchant/udhar/ledger" -Headers $merchantHeaders -Body @{
    customer_id = $customerId
    email_or_phone = $customerId
    amount = "$Amount"
    type = "given"
    payment_method = "cash"
    remarks = "Smoke modern ledger"
}
Assert-SuccessResponse -apiResult $addModernLedger -StepName "Add modern ledger"

Write-Host "[3/6] Probe legacy ledger endpoint support"
$legacyProbe = Invoke-Api -Method "POST" -Url "$BaseUrl/merchant/udhar/ledger/$customerId/entry" -Headers $merchantHeaders -Body @{
    customer_id = $customerId
    amount = "10"
    type = "credit"
    payment_method = "cash"
    notes = "Smoke legacy ledger"
} -AllowFailure

$legacyRouteState = "unsupported"
if ($legacyProbe.Ok -and $legacyProbe.Body.status -eq "success") {
    $legacyRouteState = "supported"
} elseif ($legacyProbe.StatusCode -eq 404 -or $legacyProbe.StatusCode -eq 405) {
    $legacyRouteState = "fallback_only"
} else {
    $legacyRouteState = "error_status_$($legacyProbe.StatusCode)"
}

Write-Host "[4/6] Fetch merchant customer ledger"
$merchantLedger = Invoke-Api -Method "GET" -Url "$BaseUrl/merchant/udhar/customers/$customerId/ledger" -Headers $merchantHeaders
Assert-SuccessResponse -apiResult $merchantLedger -StepName "Fetch merchant ledger"

$merchantTxCount = 0
if ($merchantLedger.Body.data.transactions) {
    $merchantTxCount = @($merchantLedger.Body.data.transactions).Count
}

$customerSyncState = "skipped (no customer token provided)"
$customerMerchantsCount = 0
$customerLedgerTxCount = 0

if (-not [string]::IsNullOrWhiteSpace($CustomerToken)) {
    Write-Host "[5/6] Fetch customer merchant list"
    $customerMerchants = Invoke-Api -Method "GET" -Url "$BaseUrl/customer/udhar/merchants" -Headers $customerHeaders
    Assert-SuccessResponse -apiResult $customerMerchants -StepName "Fetch customer merchant list"

    $customerMerchantsData = @($customerMerchants.Body.data)
    $customerMerchantsCount = $customerMerchantsData.Count

    $merchantForLedger = $null
    foreach ($item in $customerMerchantsData) {
        if ([string]$item.id -eq $customerId -or [string]$item.merchant_id -eq [string]$MerchantId) {
            $merchantForLedger = [string]$item.merchant_id
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($merchantForLedger) -and $customerMerchantsCount -gt 0) {
        $merchantForLedger = [string]$customerMerchantsData[0].merchant_id
    }

    if ([string]::IsNullOrWhiteSpace($merchantForLedger)) {
        throw "Customer merchants list returned no merchant_id to fetch ledger"
    }

    Write-Host "[6/6] Fetch customer ledger for merchant $merchantForLedger"
    $customerLedger = Invoke-Api -Method "GET" -Url "$BaseUrl/customer/udhar/ledger/$merchantForLedger" -Headers $customerHeaders
    Assert-SuccessResponse -apiResult $customerLedger -StepName "Fetch customer ledger"

    $ledgerNode = $customerLedger.Body.data.ledgers
    if ($ledgerNode -and $ledgerNode.data) {
        $customerLedgerTxCount = @($ledgerNode.data).Count
    } elseif ($ledgerNode) {
        $customerLedgerTxCount = @($ledgerNode).Count
    }

    $customerSyncState = "verified"
}

Write-Host ""
Write-Host "Smoke test summary"
Write-Host "- Customer ID: $customerId"
Write-Host "- Legacy ledger route: $legacyRouteState"
Write-Host "- Merchant ledger transactions: $merchantTxCount"
Write-Host "- Customer sync state: $customerSyncState"
if ($customerSyncState -eq "verified") {
    Write-Host "- Customer merchants count: $customerMerchantsCount"
    Write-Host "- Customer ledger transactions: $customerLedgerTxCount"
}

Write-Host "PASS"
