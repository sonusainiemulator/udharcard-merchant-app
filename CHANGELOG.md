# Changelog

All notable changes to the **UdharCard Merchant Mobile Application** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.11] - 2026-07-28

### ✨ Enhancements & Bug Fixes
- **India Phone Number UI & Validation**:
  - Added an explicitly styled "🇮🇳 +91" prefix to the mobile login fields (`login_screen.dart`, `firebase_phone_login_screen.dart`).
  - Added logic in `AuthController` to automatically prepend `+91` if missing, completely fixing the Firebase E.164 formatting error when users type 10-digit mobile numbers.

---

## [1.0.10] - 2026-07-28

### 🐛 Bug Fixes
- **Login UI Flickering**: Fixed an issue where the login screens flickered rapidly when typing a phone number by optimizing the widget rebuild tree in `login_screen.dart` and `firebase_phone_login_screen.dart`.

---

## [1.0.9] - 2026-07-27

### 🔐 Persistent Auth & Session Timeout Fix
- **Prevented Premature Logout**: Updated `api_error.dart` to prevent background 401 HTTP errors from kicking authenticated merchants back to `LoginScreen` after 2-3 minutes.
- **Session Token Persistence**: Saved Firebase Auth token, user ID, and merchant profile permanently in local storage (`HiveHelp`).
- **Splash Screen Persistence Check**: Updated `SplashScreen` to verify both local token and `FirebaseAuth.instance.currentUser` before routing.

---

## [1.0.8] - 2026-07-27

### 📱 Default Mobile Number Login System
- **Mobile OTP Login**: Set mobile number + OTP verification as the primary default authentication method on Login and Register screens.
- **Removed Username & Password**: Purged traditional username and password fields to streamline merchant onboarding.
- **Android Platform Specifics**: Automatically hid Apple sign-in on Android devices while expanding Google sign-in to full width.

---

## [1.0.7] - 2026-07-27

### 🎨 Premium Social & WhatsApp Buttons
- **Google Brand Icon**: Added official vector icon via `font_awesome_flutter` to guarantee crisp rendering across all screen densities.
- **Apple Brand Icon**: Added official Apple vector icon with dark card contrast styling.
- **WhatsApp OTP Action**: Upgraded to brand-gradient WhatsApp green button (`#25D366` to `#128C7E`) with soft shadow elevation.

---

## [1.0.6] - 2026-07-27

### 🍏 iOS Rebrand
- **iOS App Name**: Updated Display Name and Bundle Name to **Udharcard Merchant**.
- **iOS Bundle Identifier**: Set `PRODUCT_BUNDLE_IDENTIFIER` to `com.udharcard.merchant` across Debug, Profile, and Release Xcode configurations.

---

## [1.0.5] - 2026-07-27

### 🎨 UI & UX Overhaul
- **Redesigned Login & Registration Pages**:
  - Prominent high-res app logo header with shadow/glow styling.
  - "MERCHANT PORTAL" & "MERCHANT REGISTRATION" gradient pill badges.
  - Cleaned up excessive vertical padding for compact, sleek scrolling.
  - WhatsApp & Phone OTP button styled with WhatsApp green branding.
  - Added bottom branding footer (`AuthFooterBranding`):
    - 🔒 **100% Secure & Trusted**
    - 🇮🇳 **Made in India**
    - 💼 **Designed by Rakebig Services**

---

## [1.0.4] - 2026-07-27

### 🐛 Fixed
- **Firebase Initialization Error**:
  - Added missing `google-services.json` to `android/app/` for `com.udharcard.merchant.app`.
  - Applied `com.google.gms.google-services` plugin in Android Gradle files.
  - Added robust fallback `FirebaseOptions` in `lib/main.dart` to prevent `[core/no-app] No Firebase App '[DEFAULT]' has been created` error on OTP verification / Login with Phone.

---

## [1.0.3] - 2026-07-26

### ✨ Added
- **Mobile Number Verification Enforcement**:
  - Merchants must add a mobile number before sending SMS/WhatsApp alerts.
  - "Mobile Number Required" dialog with redirect to Edit Profile screen.
  - Applied across Home, Customer List, and Customer Ledger screens.

### 🔧 Improved
- **Versioned APK Naming**: Release APK now includes version info (e.g., `udharcard-merchant-app-v1.0.3-4-release.apk`).

---

## [1.0.2] - 2026-07-26

### ✨ Added
- **Social Login (Google & Apple)**:
  - Added "Continue with Google" and "Continue with Apple" UI buttons to the Login and Registration screens.
  - Added new dependencies `google_sign_in` and `sign_in_with_apple`.
  - Added stub methods to `AuthController` for backend integration.

---

## [1.0.1] - 2026-07-26

### ✨ Added
- **NFC Tap & Pay (Coming Soon)**:
  - Added a new UI element on the home screen for the upcoming NFC feature.
  - Tapping the button displays a friendly "Coming Soon" message to users while backend and reader requirements are finalized.

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
