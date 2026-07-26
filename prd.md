# Product Requirement Document (PRD) - UdharCard Merchant App

## 1. Product Overview & Vision
The **UdharCard Merchant App** is a digital ledger solution designed for merchants to manage customer credit transactions (Udhar) and collections. It replaces paper ledger books (Khata) with a real-time, cloud-synced system, incorporating automatic outstanding calculations, dynamic UPI QR code payments, automated notifications, and reporting dashboards.

---

## 2. Core Functional Modules

### 2.1 Merchant Authentication
- **Mobile OTP Login**: Fast login using mobile number verified via Firebase SMS OTP or Custom SMS Gateway.
- **Email Login & Registration**: Standard login using secure credentials with password hashing.
- **KYC Verification**: A multi-step form to upload shop details, license, PAN/Aadhaar cards. KYC status can be: `Pending`, `Approved`, or `Rejected` (managed by the Admin Panel).

### 2.2 Customer Management
- **Customer List**: A list of all customers with search and filters (e.g., Outstanding Balance > 0, Active/Inactive, Credit Limit exceeded).
- **Customer Profile**: View name, phone, email, current balance, credit limit, and history.
- **Verification**: Mobile number validation for customers.
- **Credit Limit Control**: Define a maximum credit limit per customer. Prevent credit entry if it exceeds the limit (optional merchant setting toggle).

### 2.3 Udhar Ledger System
- **Opening Balance**: Assign an initial credit/debit balance when a customer is added.
- **Credit Entry ("Udhar Diya")**: Record a new debt transaction. Outstanding balance increases.
- **Debit Entry ("Payment Received")**: Record payment received from the customer. Outstanding balance decreases.
- **Ledger Timeline**: Real-time chronological feed of transactions for both parties with running balance calculations.
- **Due Date Management**: Set payment deadlines for each credit entry.

### 2.4 Merchant Dashboard
- **Total Credit Given**: Cumulative active credit across all customers.
- **Total Amount Received**: Cumulative cash/digital payments collected.
- **Pending Collection**: Unpaid balances that are overdue.
- **Active Customers**: Count of customers with transactions in the last 30 days.
- **Today's & Monthly Reports**: Interactive graphs showing credit vs collections.

### 2.5 QR Payment System
- **Static QR**: General merchant QR linked to the merchant account. Customer enters the amount and pays.
- **Dynamic QR**: Unique QR code generated for a specific customer and specific amount. It embeds transaction remarks and payment amounts into the UPI string.
- **Sharing**: Send QR codes directly via WhatsApp, SMS, or native Share link.
- **Auto-reconciliation**: Upon successful webhook response from the payment gateway (Razorpay/PhonePe), the customer's ledger is automatically updated (balance decreases).

### 2.6 Notification System
- **Payment Reminders**: Automated/manual notifications sent via WhatsApp API, SMS, or Push notifications.
- **Webhook Updates**: Trigger real-time notifications to the merchant when a customer makes an online payment.

### 2.7 Reports Module
- **Ledger Statement**: Export full ledger statements in PDF/Excel formats.
- **Outstanding Balance Report**: Summary of all customer balances.
- **Daily/Monthly Collection Report**: Financial breakdown of cash vs online entries.

---

## 3. Database Architecture (MySQL)

### `merchants`
- `id` (INT, PK, Auto-Increment)
- `name` (VARCHAR)
- `email` (VARCHAR, Unique)
- `phone` (VARCHAR, Unique)
- `password` (VARCHAR)
- `shop_name` (VARCHAR)
- `kyc_status` (ENUM: 'pending', 'approved', 'rejected')
- `created_at` / `updated_at` (TIMESTAMP)

### `customers`
- `id` (INT, PK, Auto-Increment)
- `merchant_id` (INT, FK -> `merchants.id`)
- `name` (VARCHAR)
- `phone` (VARCHAR)
- `email` (VARCHAR, Nullable)
- `opening_balance` (DECIMAL(10,2))
- `outstanding_balance` (DECIMAL(10,2))
- `credit_limit` (DECIMAL(10,2))
- `created_at` / `updated_at` (TIMESTAMP)

### `transactions`
- `id` (INT, PK, Auto-Increment)
- `customer_id` (INT, FK -> `customers.id`)
- `merchant_id` (INT, FK -> `merchants.id`)
- `amount` (DECIMAL(10,2))
- `type` (ENUM: 'credit' (given), 'debit' (received))
- `payment_method` (ENUM: 'cash', 'upi', 'bank_transfer', 'qr_code')
- `remarks` (TEXT, Nullable)
- `due_date` (DATE, Nullable)
- `transaction_id` (VARCHAR, Unique, Nullable)
- `status` (ENUM: 'pending', 'completed', 'failed')
- `created_at` (TIMESTAMP)

---

## 4. API Endpoint Specifications

### 4.1 Merchant Authentication
- `POST /api/register`
  - Body: `name`, `email`, `phone`, `password`, `shop_name`
- `POST /api/login`
  - Body: `email` or `phone`, `password`
  - Response: `{ "status": "success", "token": "JWT_TOKEN", "merchant": {...} }`
- `POST /api/kyc/submit` (Multipart)
  - Fields: `pan_card_number`, `aadhaar_number`, files: `pan_doc`, `aadhaar_doc`

### 4.2 Customer Management
- `GET /api/merchant/users` (Get list of customers)
- `POST /api/merchant/users/add`
  - Body: `name`, `phone`, `email`, `credit_limit`, `opening_balance`
- `PUT /api/merchant/users/update/{id}`
- `DELETE /api/merchant/users/delete/{id}`

### 4.3 Udhar & Ledger
- `POST /api/merchant/udhar`
  - Body: `email_or_phone`, `amount`, `type` ('given' | 'received'), `remarks`, `due_date`
  - Description: Records credit or debit, recalculates `outstanding_balance` on the customer.
- `GET /api/merchant/ledger/{customer_id}`
  - Response: Transaction list, customer details, outstanding balance, and credit limit usage.

### 4.4 QR Codes & Payments
- `GET /api/merchant/qr/generate`
  - Query Params: `customer_id`, `amount` (optional)
  - Response: UPI URI (e.g. `upi://pay?pa=merchant@upi&pn=ShopName&am=Amount&tn=Remark`) and QR Code image URL.
- `POST /api/payment/webhook`
  - Process gateway webhook (PhonePe/Razorpay) and update the customer ledger on successful debit.
