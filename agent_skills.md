# Agent Skills & Execution Plan - UdharCard Developer Guidelines

This document provides developer guidelines, code patterns, and an execution checklist for building the UdharCard Merchant App features on both Flutter and Laravel stack.

---

## 1. Technical Standards

### 1.1 Flutter Development Guidelines
- **State Management**: Use **GetX** (`GetBuilder`, `GetxController`). Always separate views from controller files.
- **Layout & Responsiveness**: Use `flutter_screenutil` (e.g., `100.h`, `20.w`, `16.sp`, `12.r`) to ensure UI scaling on all devices.
- **Color System**: Consume the existing `AppColors` definitions. Use HSL/transparent overlays for premium visual design:
  - Credit: `AppColors.redColor` or transparent red card.
  - Payment: `AppColors.greenColor` or transparent green card.
- **Themes**: Handle dark/light mode switches gracefully. Avoid hardcoding `Colors.white` or `Colors.black` directly; use context extensions like `context.t` or `Get.isDarkMode`.
- **Imports**: Resolve dependencies cleanly using package/relative paths (e.g., `import '../../../controllers/bindings/controller_index.dart';`).

### 1.2 Laravel REST API Guidelines
- **Controller Design**: Use resource controllers (`index`, `store`, `show`, `update`, `destroy`).
- **Input Validation**: Always use Laravel FormRequests to validate body fields (e.g. `amount`, `phone`, `email`).
- **Database Safety**: Wrap ledger balance updates in database transactions (`DB::transaction`) to avoid race conditions:
  - If a credit/debit transaction fails to save, rollback balance recalculations.
- **Response Format**: Return consistent JSON structures:
  ```json
  {
    "status": "success",
    "message": "Udhar transaction recorded successfully",
    "data": { ... }
  }
  ```

---

## 2. Implementation Checklist & Agent Tasks

### Task 1: Customer Management Setup (Flutter)
- [ ] Add `CustomerListScreen` displaying all customers and outstanding balance summary cards (Total Credit Given vs Collections).
- [ ] Create `AddCustomerDialog` prompting for: Name, Mobile, Email, and Credit Limit.
- [ ] Connect the front-end forms with backend endpoint `POST /api/merchant/users/add`.

### Task 2: Udhar Ledger & Balance Timeline (Flutter)
- [ ] Add `CustomerLedgerScreen` displaying a timeline log of Credit (Udhar Diya) and Debit (Payment Received) events.
- [ ] Implement color code logic for entries (Red for given, Green for wapas).
- [ ] Display due date alerts if a transaction is overdue.
- [ ] Add a quick "Send WhatsApp Alert" button that pre-fills message template:
  > *Hi [Customer Name], you have a pending payment of ₹[Amount] due on [Date]. Please pay using: [UPI Link/QR Link]*

### Task 3: Dynamic QR Code Generator (Flutter)
- [ ] Create a "Receive Payment" option on `CustomerLedgerScreen` that opens a sheet to input a custom amount.
- [ ] Draw a dynamic UPI QR using `QrImageView` using parameters:
  - UPI ID (from Merchant Settings)
  - Amount
  - Transaction reference number
- [ ] Add a native Share button to share the UPI deep link or QR image to WhatsApp.

### Task 4: Reports & Outstanding Exports (Flutter)
- [ ] Create a `ReportsDashboard` page in settings or drawer.
- [ ] Create templates for:
  - Full Ledger Statement (PDF)
  - Outstanding balances sheet (Excel/CSV)
- [ ] Implement `open_file` package to view downloaded reports on the device.

### Task 5: Database Migrations & API Endpoints (Laravel)
- [ ] Write migrations for `customers` and `transactions` tables.
- [ ] Write logic in `TransactionController` to update `outstanding_balance` on the corresponding customer record upon creation:
  - If `type` is `credit`: `outstanding_balance += amount`.
  - If `type` is `debit`: `outstanding_balance -= amount`.
- [ ] Integrate Razorpay / UPI webhooks to receive online payment notifications and automatically create a debit entry on the database.
