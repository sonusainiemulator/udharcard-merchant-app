# Changelog

All notable changes to the **UdharCard Merchant Mobile Application** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-07-24

### 🚀 Highlights & Initial Release
Initial official release of the **UdharCard Merchant App**, a comprehensive digital ledger, payment processing, payout/withdrawal, and credit management system for merchants developed by Rakebig Services.

---

### ✨ Added

#### 🔐 Authentication & Security
- **Firebase Phone OTP Authentication**:
  - Integrated `firebase_core` and `firebase_auth` for fast, secure phone number OTP authentication.
  - Added [FirebasePhoneLoginScreen](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/views/screens/auth/firebase_phone_login_screen.dart) for seamless phone entry.
  - Added [FirebaseOtpVerifyScreen](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/views/screens/auth/firebase_otp_verify_screen.dart) for fast 6-digit verification code input.
  - Updated [AuthController](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/controllers/auth_controller.dart) to manage Firebase verification IDs and credential sign-in flows.
  - Initialized Firebase services asynchronously in [main.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/main.dart).
- **Email & Password Authentication**:
  - Traditional email/password merchant sign-in and registration (`login_screen.dart`, `register_screen.dart`).
  - Forgot password flow with OTP recovery (`forgot_pass_screen.dart`, `create_new_pass_screen.dart`).
- **Security & PIN Setup**:
  - Security PIN setup screen for quick merchant app authorization (`security_pin_setup_screen.dart`).
  - Two-Factor Authentication (2FA) verification system (`two_fa_verification_screen.dart`).
  - Identity verification and KYC submission system (`identity_verification_screen.dart`).

#### 📒 Udhar (Credit/Ledger) Management
- **Udhar Dashboard**: Real-time summary of total give/take amounts, recent transactions, and quick action shortcuts (`udhar_dashboard_screen.dart`).
- **Customer Directory**: Searchable list of registered customers with outstanding balances (`customer_list_screen.dart`).
- **Customer Ledger View**: Detailed line-item transaction history per customer (`customer_ledger_screen.dart`).
- **Add Udhar Record**: Dynamic entry form to log credit (gave) or debit (received) transactions with notes (`add_udhar_screen.dart`).
- **Voice Entry Engine**: AI & Offline NLP hands-free voice assistant for logging udhar transactions via voice commands (`voice_entry_screen.dart`, `voice_entry_controller.dart`). Supports dual-processing via Gemini AI and local regex parser fallback.

#### 💳 Payments, Withdrawals & Wallet
- **Dual QR Code Payments**: Integrated system-generated QR code alongside **Custom Merchant QR Upload** (`qr_code_screen.dart`). Allows merchants to pick static QR images from Gallery or Camera with persistent local Hive caching.
- **Withdrawal Engine**: Multi-gateway withdrawal/payout support including Flutterwave and custom bank gateways (`withdraw_screen.dart`, `flutter_wave_withdraw_screen.dart`).
- **Withdrawal History & Preview**: Complete payout history tracking with status indicators (`withdraw_history_screen.dart`, `withdraw_preview_screen.dart`).
- **Transaction Logs**: Detailed transaction history filterable by date, type, and status (`transaction_screen.dart`).
- **Payment Success & Failure Feedback**: Custom animated success/failure modals (`payment_success_screen.dart`, `app_payment_fail.dart`).

#### 👤 Merchant Profile & Settings
- **Profile Management**: Profile picture upload, personal info updates, and address configuration (`edit_profile_screen.dart`, `profile_setting_screen.dart`).
- **Merchant Store Settings**: Store setup, business details, and operational preference configuration (`merchant_settings_screen.dart`).
- **Notification Settings**: Granular push notification preferences and permission handling (`notification_settings_controller.dart`, `notification_permission_screen.dart`).
- **Account Deletion**: Self-service account deletion request workflow with confirmation (`delete_account_screen.dart`).

#### 🎫 Support Ticket System
- **Create Support Ticket**: Submit customer support requests with attachment capabilities (`create_support_ticket_screen.dart`).
- **Ticket List & Detailed View**: Real-time conversation thread view for active and closed support tickets (`support_ticket_list_screen.dart`, `support_ticket_view_screen.dart`).

#### 🎨 Design System & Infrastructure
- **GetX Architecture**: Complete state management, dependency injection (`bindings.dart`), and reactive UI updates across all modules.
- **Custom UI Component Library**: Custom reusable textfields (`app_textfield.dart`, `custom_textfield.dart`), searchable dropdowns (`custom_searchable_dropdown.dart`), custom buttons (`app_button.dart`), and responsive layout extensions (`mediaquery_extension.dart`).
- **Theming & Localization**: Centralized light/dark theme configurations ([themes.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/themes/themes.dart)) and color palettes ([styles.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/config/styles.dart)).
- **Local Storage**: Hive integration for fast local caching of tokens and user preferences (`init_hive.dart`).
