# Changelog

All notable changes to the **UdharCard Merchant Mobile Application** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.40] - 2026-08-04

### 🛠️ Universal AppBar Back Navigation Fix
- **Enhanced CustomAppBar Navigation Engine**: Updated [custom_appbar.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/views/widgets/custom_appbar.dart) default `onPressed` handler to check `Navigator.of(context).canPop()` and `Get.key.currentState?.canPop()`. When popping is not possible (such as when switching top-level bottom navigation tabs or deep-linked routes), it gracefully switches back to the main Home tab (`BottomNavController.to.changeScreen(0)`).
- **Fixed Hidden & Misconfigured AppBars**: Removed hardcoded `SizedBox` leading overrides in `MerchantSettingsScreen`, `TransactionScreen`, and `VerificationCheckScreen` so back arrows are fully visible and responsive.
- **Unified Custom AppBars**: Standardized `SubscriptionPlansScreen` and `AddCustomerScreen` back actions to ensure consistent 1-tap navigation back to preceding screens across all Android devices.
- **Root Home Tab Cleaner**: Ensured the root `HomeScreen` header cleanly suppresses redundant leading back arrows on the main merchant landing dashboard.

## [1.0.39] - 2026-08-04

### ✨ Optional Subscription Enrollment for Merchant Onboarding
- **Made Plan Enrollment Optional**: Added a shared `subscriptionEnrollmentRequired` flag so merchant onboarding and app launch can go straight to the dashboard when plan selection is not being enforced.
- **Added Skip Path on Plan Screen**: The subscription screen now shows a **Skip for now** action that clears partial subscription state and launches the merchant dashboard immediately.
- **Preserved Re-Enable Path**: Plan selection can be forced back on later by setting the enrollment flag to `true`, without changing the onboarding or subscription screen structure.

## [1.0.38] - 2026-08-03

### 📊 Udhar Reports Dashboard, Device Exports, and Backend Route Wiring
- **Added Reports Dashboard**: Introduced a new in-app reports hub with range filtering, collections summary cards, outstanding customer ranking, and recent ledger activity review.
- **Added Device-Openable Exports**: Merchants can now generate a **full ledger statement PDF** and an **outstanding balances CSV** directly on the device, with files opened using the native file handler.
- **Wired Merchant Udhar Routes**: Registered local Laravel routes for customer list/create/update/delete, ledger fetch/create, Razorpay webhook ingestion, and udhar report aggregation so the Flutter endpoints match actual backend routes.

## [1.0.37] - 2026-08-03

### 💳 Merchant Subscription & Billing Engine
- **Subscription Controller & Repository**: Added [subscription_controller.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/controllers/subscription_controller.dart) and [subscription_repo.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/data/repositories/subscription_repo.dart) for plan discovery, subscription activation, auto-renewal settings, and billing status tracking.
- **Subscription Gate Service**: Implemented [subscription_gate_service.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/utils/services/subscription_gate_service.dart) to enforce tier-based feature access across merchant workflows.
- **Laravel Billing API & Database Migrations**: Created subscription models, API controllers (`SubscriptionController.php`, `SubscriptionPaymentController.php`), and schema migration `2026_08_03_000000_create_subscription_billing_tables.php`.

### 📋 Merchant WorkList & Task Management
- **WorkList Controller & UI**: Built [worklist_controller.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/controllers/worklist_controller.dart) and task management screens in `lib/views/screens/worklist/` for tracking merchant daily operations, customer follow-ups, and pending tasks.
- **Laravel WorkList Backend**: Added backend API endpoints and schema migration `2026_08_03_010000_create_work_list_items_table.php`.

### 🌐 Multi-Language Support & Onboarding Enhancements
- **Language Service & Sheet**: Added [language_service.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/utils/services/language_service.dart) and modal bottom sheet `LanguageSelectionSheet` for seamless English/Hindi locale toggling.
- **Merchant Onboarding Wizard**: Integrated `MerchantOnboardingWizardScreen` and `CompleteProfileOnboardingSheet` into post-registration authentication flow.

### 🐛 Merchant App Registration Payload & Form-Encoding Fix
- **Fixed Registration API Payload Format**: Updated [api_client.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/data/source/network/api_client.dart) to send `application/x-www-form-urlencoded` payloads for POST requests instead of raw JSON (`application/json`).
- **Verified CLI Registration**: Tested merchant account creation via CLI (`ID: 229`, `username: climatch1`, `phone: 9876500001`).

---

## [1.0.36] - 2026-08-01

### 🎨 Edit Profile UI Overhaul & Simplified Name Field
- **Unified Full Name Field**: Replaced separate "First Name" and "Last Name" input fields with a single, intuitive **"Full Name / Owner Name"** field that automatically syncs names to backend profile fields.
- **Hidden Username Option**: Hidden/removed username input option entirely from Edit Profile UI.
- **Fixed India 🇮🇳 (+91) Phone Prefix**: Fixed India country code badge and 10-digit input format before the mobile number field.
- **Card-Based Fintech Design**: Enhanced Edit Profile UI layout with section cards ("Merchant Details", "Contact", "Preferences", "Address Details"), camera photo upload overlay, and elevated **Update Profile** button.

---

## [1.0.35] - 2026-08-01

### 📊 3-Metric Financial Summary Cards (Total Diya, Total Mila, Pending)
- **3 Dynamic Metrics Header**: Updated the financial header cards on [home_screen.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/views/screens/home/home_screen.dart) and [udhar_dashboard_screen.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/views/screens/udhar/udhar_dashboard_screen.dart) to display 3 distinct live metrics:
  1. 🔴 **Total Diya**: Sum of all credit given to customers.
  2. 🟢 **Total Mila**: Sum of all payments received from customers.
  3. 🔵 **Pending**: Net outstanding pending balance (`Total Diya - Total Mila`).
- **High-End Styling**: Enhanced card typography, colors, and layout dividers for instant clarity.

---

## [1.0.33] - 2026-08-01

### 🎨 Bottom Sheet Save Button UI & Safe Inset Padding Fix
- **System Navigation Inset Padding**: Fixed bottom cutoff issue on [add_customer_sheet.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/views/screens/udhar/add_customer_sheet.dart) by adding `MediaQuery.of(context).padding.bottom` safe inset padding. The **Save Customer** button is now fully visible and elevated cleanly above system navigation bars across all Android screen sizes.
- **Button Contrast & Styling**: Changed icon and label text color to crisp bold white (`#FFFFFF`) on primary blue background (`#175CD3`) for high contrast and maximum legibility.

## [1.0.32] - 2026-08-01

### 🌐 Mandatory Real-Time API Execution & Internet Connection Notice
- **Disabled Offline Fallback Mode**: Removed local queue caching and offline mock responses across all screens in [api_client.dart](file:///c:/Users/erson/Downloads/sk/01_PaySecure-Mobile_App/03_Merchant_Mobile_App/Source%20Code/project/lib/data/source/network/api_client.dart). Every single screen and action is forced to execute live real-time backend API calls (`_BASE_URL + ENDPOINT_URL`).
- **Interactive Internet Issue Notice (`CustomDialog`)**: If a live network call fails due to no internet connection or server timeout, the app automatically presents a high-end **"Internet Connection Issue"** dialog informing the merchant to check their mobile data/Wi-Fi connection with a 1-tap **"Check Connection Again"** action.

---

## [1.0.31] - 2026-08-01

### ✨ Multi-Step Merchant Onboarding Wizard Flow
- **Interactive 3-Step Wizard (`MerchantOnboardingWizardScreen`)**: Created a guided onboarding wizard for all newly registered merchants:
  - 🏪 **Step 1: Store & Category**: Collects Shop Name and Category Selection Chips (*Kirana & Grocery*, *Electronics*, *Clothing*, *Medical*, *Services*, etc.).
  - 💳 **Step 2: Payment Collection Setup**: Configures Merchant UPI ID (for QR collections & WhatsApp payment links) and displays supported payment app collection modes.
  - 📍 **Step 3: Business Location**: Captures Store Locality/Address, City, and Pincode.
- **Progress Tracking & Routing**: Added step indicator progress bar (Step 1 of 3 -> Step 3 of 3), Back/Next step navigation, and automatic post-registration routing from `AuthController`.
- **Skip Support**: Added "Skip Wizard" option so merchants can access their dashboard instantly.

---

## [1.0.30] - 2026-08-01

### 🚫 Top Popup Notification Removal
- **Removed Top Popup Banners**: Completely suppressed/disabled top popup snackbars (`Get.snackbar` / `Helpers.showSnackBar`) across all screens and auth flows.
- **Strict In-Page Error Display**: All authentication notices, Firebase limit errors, and status feedback now display strictly as clean inline UI cards directly inside the active page canvas.

---

## [1.0.29] - 2026-08-01

### ✨ Post-Registration Merchant Profile Onboarding
- **Guided Merchant Profile Sheet (`CompleteProfileOnboardingSheet`)**: Added automated post-registration profile onboarding modal asking merchants for **Shop Name**, **Business Category**, **Merchant UPI ID**, and **Store City/Location**.

---

## [1.0.28] - 2026-08-01

### 🐛 Merchant Registration Backend Sync & Payload Fix
- **Backend API Field Alignment**: Fixed merchant onboarding failure by populating required backend fields: `firstname`, `lastname`, `password`, `password_confirmation`, `phone_code`, `country`, and `country_code`.

---

## [1.0.27] - 2026-08-01

### ✨ Multi-Step Merchant Onboarding Wizard Flow
- **Interactive 3-Step Wizard (`MerchantOnboardingWizardScreen`)**: Created a guided onboarding wizard for all newly registered merchants:
  - 🏪 **Step 1: Store & Category**: Collects Shop Name and Category Selection Chips (*Kirana & Grocery*, *Electronics*, *Clothing*, *Medical*, *Services*, etc.).
  - 💳 **Step 2: Payment Collection Setup**: Configures Merchant UPI ID (for QR collections & WhatsApp payment links) and displays supported payment app collection modes.
  - 📍 **Step 3: Business Location**: Captures Store Locality/Address, City, and Pincode.
- **Progress Tracking & Routing**: Added step indicator progress bar (Step 1 of 3 -> Step 3 of 3), Back/Next step navigation, and automatic post-registration routing from `AuthController`.
- **Skip Support**: Added "Skip Wizard" option so merchants can access their dashboard instantly.

---

## [1.0.30] - 2026-08-01

### 🐛 Login Screen — Flickering Fix
- **Root Cause Eliminated**: Converted `LoginScreen` from `StatefulWidget` to `StatelessWidget` — removed `TextEditingController.addListener(_refreshForm)` + `setState()` that was causing the entire login screen to `build()` on every single keystroke typed in the phone number field.
- **Scoped Rebuild Only**: The only dynamic section (Continue button loading state + error message banner) is wrapped in `GetBuilder<AuthController>` with a scoped ID `authSubmissionUpdateId` — typing in the phone field now triggers **zero** screen-wide rebuilds.
- **FutureBuilder Flicker Fix**: Extracted `PackageInfo.fromPlatform()` from inline `FintechAuthPage` (`StatelessWidget`) into a dedicated `_AppVersionText` `StatefulWidget` — future is now initialized once in `initState` and never restarted on parent rebuilds.

## [1.0.26] - 2026-08-01

### 🐛 Login Screen — Flickering Fix
- **Root Cause Eliminated**: Converted `LoginScreen` from `StatefulWidget` to `StatelessWidget` — removed `TextEditingController.addListener(_refreshForm)` + `setState()` that was causing the entire login screen to `build()` on every single keystroke typed in the phone number field.
- **Scoped Rebuild Only**: The only dynamic section (Continue button loading state + error message banner) is wrapped in `GetBuilder<AuthController>` with a scoped ID `authSubmissionUpdateId` — typing in the phone field now triggers **zero** screen-wide rebuilds.
- **FutureBuilder Flicker Fix**: Extracted `PackageInfo.fromPlatform()` from inline `FintechAuthPage` (`StatelessWidget`) into a dedicated `_AppVersionText` `StatefulWidget` — future is now initialized once in `initState` and never restarted on parent rebuilds.
- **Removed Stale `initState` Code**: Removed `clearFirebaseOtpController()` + postFrameCallback `setState` that ran every time the login screen was pushed onto the navigator stack.
- **Zero Logic Regression**: All login functionality unchanged — phone validation, OTP dispatch via `sendFirebaseOtp`, error message display, and navigation to Register screen all work identically.

### 🔐 Merchant Account Existence Verification Before OTP (Verified & Live Tested)
- **Pre-OTP Gate**: Before sending any Firebase OTP, `sendFirebaseOtp()` calls `_checkMerchantAccountExists()` which hits `POST /api/merchant/check-exist` — OTP is **never dispatched** to Firebase if the merchant account does not exist.
- **API Response Handling**: Backend returns `HTTP 404 + {status:"error", exists:false, message:"Merchant account does not exist. Please register first."}` for unregistered numbers — app correctly parses both the HTTP status code and `exists` field.
- **Error Banner Shown**: If account not found, login screen shows inline error: *"Merchant account does not exist. Please register first."* — button re-enables, user can correct the number.
- **Login Fallback**: If `check-exist` endpoint is unreachable, app falls back to a dummy-password login call to infer existence from the error message (`"Invalid username"` → not found, `"Invalid password"` → account exists).
- **Offline Fail-Open**: On complete network failure, app allows OTP to proceed so legitimate merchants are not locked out when offline.
- **Live CLI Test Results**: Tested `POST /api/merchant/check-exist` with multiple non-registered 10-digit numbers — all returned `HTTP 404 + exists:false` — confirmed OTP is blocked in all cases.

### 🧪 End-to-End Testing & Code Hygiene
- **Verified Login Flow (`+91 99924 33121`)**: Live tested `POST /api/merchant/check-exist` with registered number `9992433121` and `+919992433121` — confirmed `HTTP 200` + `exists: true`. Verified pre-OTP gating, Firebase Auth dispatch, token persistence, and navigation logic.
- **Unused Import Cleanup**: Cleaned up unused imports across `edit_profile_screen.dart`, `profile_setting_screen.dart`, `chat_ledger_screen.dart`, and `udhar_dashboard_screen.dart`.

---

## [1.0.25] - 2026-08-01



### 🎨 Edit Profile UI Overhaul
- **Redesigned Edit Profile Screen**: Complete UI rewrite with modern card-based sectioned layout — Personal Info, Contact, Preferences, and Address Details cards replacing plain flat fields.
- **Username Field Hidden**: Removed username input from Edit Profile UI; username field no longer shown to merchant.
- **Name Fields Simplified**: "First Name" and "Last Name" shown as two clean separate labelled fields inside a single card section.
- **India Fixed as Default Country Code**: Replaced the full `CountryCodePicker` dropdown with a static India 🇮🇳 +91 prefix — country code is now hardcoded to India and sent as `+91`/`IN` on profile update.
- **Improved Profile Photo Header**: Circular avatar with `mainColor` border, inline name + email subtitle, and camera overlay button.
- **Better Photo Picker Sheet**: Redesigned camera/gallery bottom sheet with card-style buttons and icons.
- **Validation Update**: Removed username-required validation from `ProfileController.validateEditProfile()`; only First Name, Last Name, and Phone are required.
- **Default Country Reset**: `ProfileController` now defaults `countryCode = 'IN'`, `phoneCode = '+91'`, `countryName = 'India'` instead of US.

### 🐛 Add Customer Sheet — Save Button Fix
- **Sticky Save Button**: `Save Customer` button is now always visible above the keyboard — restructured sheet to use a `Column` with `mainAxisSize: min` so the button never gets pushed off-screen when keyboard appears.
- **Fields Cleared on Open**: `nameCtrl`, `phoneCtrl`, `emailCtrl`, `limitCtrl` are all cleared when the sheet opens, preventing stale data from previous sessions.
- **Loading State**: Button shows `CircularProgressIndicator` icon + "Saving..." label while `isAddingCustomer` is true, and disables itself to prevent double-submit.
- **Keyboard Dismiss on Save**: `FocusScope.unfocus()` called before `addCustomer()` so keyboard closes cleanly on save tap.
- **Refactored to StatelessWidget**: Sheet content extracted to `_AddCustomerSheetContent` `StatelessWidget` so `GetBuilder<UdharController>` properly rebuilds the button's loading state.
- **Input Formatters**: Phone number field now enforces digits-only with max 15 characters; credit limit enforces digits-only.

---

## [1.0.24] - 2026-07-31


### 🎨 Premium Fintech UI & Typography Overhaul
- **Redesigned Merchant UPI Address Modal Sheet**: Fixed oversized headline typography (`displaySmall`/`displayMedium`) to clean, legible `bodyMedium` (`13.sp` with `1.4` height) and `18.sp` bold title.
- **Enhanced Safe Area Insets**: Added top drag handle indicator and padded `bottom` to `MediaQuery.of(context).viewInsets.bottom + 16.h + MediaQuery.of(context).padding.bottom`, preventing system soft navigation buttons (`< o |||`) from overlapping the **Save UPI ID** primary button.

---

## [1.0.23] - 2026-07-31

### 📱 Layout & Safe Area Improvements
- **Bottom Safe Area Inset Padding**: Added safe area inset bottom padding across all modal bottom sheets (`Add Customer Sheet`, `Edit Limit Sheet`, `Select Customer Sheet`, `Reminder Modals`) and `Add Udhar Screen`, preventing buttons and text fields from being clipped on edge-to-edge gesture navigation displays.
- **Motorola & Android 15 Real Device Compatibility**: Optimized deployment and UI rendering for modern Android devices (including Motorola Edge 40 Neo).

---

## [1.0.22] - 2026-07-31

### ⚡ Instant Profile Rendering & Backend Deployment
- **Instant Local Hive Fallback**: Implemented local storage fallback in `ProfileController` so merchant profile details (Name, Email, Phone) appear instantly upon signup or app launch.
- **Backend Patch Package**: Bundled updated Laravel backend controllers (`AuthController.php`, `CustomerUdharController.php`, `UdharController.php`, `User.php`, `api.php`) into `backend_patch_files.zip` for manual server deployment.

---

## [1.0.21] - 2026-07-31

### 📱 Mobile Number Constraints
- **10-Digit Constraint on Login Screen**: Restricted login mobile input field to exactly 10 digits and numbers only, preventing users from entering country codes twice or typing more than 10 digits.

---

## [1.0.20] - 2026-07-31

### 🚀 Voice & Sync Enhancements
- **Voice Entry TalkBack**: Improved accessibility features for Voice Entry screen.
- **Merchant Auth & Profile Backend Sync**: Robust state management and database synchronization on merchant login and profile updates.
- **Udhar History Auto-Linking**: Automatically linked historical customer ledger entries upon account onboarding.
- **VPS Patches**: Implemented backend connection and session patches.

---

## [1.0.18] - 2026-07-29

### 🎨 Complete Mobbin-Inspired Fintech UI Redesign
- **Centralized Fintech UI System**: Introduced `FintechUI` component kit (`fintech_ui_kit.dart` & `fintech_auth_widgets.dart`) with modern elevated cards, standardized primary CTA buttons, and high-legibility input fields.
- **Minimalist Splash Screen**: Redesigned `splash_screen.dart` with a clean white canvas, smooth logo fade & slide entrance animations, and refined typography.
- **Onboarding Experience**: Redesigned `onbording_screen.dart` with card-encapsulated illustrations, top branding bar, animated pill page indicators, and modern CTA buttons.
- **Authentication Screens**: Re-architected `login_screen.dart` and `register_screen.dart` into clean, high-security layouts with "+91" mobile number prefixes, alert error banners, and bank-grade trust badges.
- **Modern Bottom Navigation Bar**: Upgraded `bottom_nav_bar.dart` into a high-elevation, animated soft-pill navigation bar with active tab highlights inspired by top-tier banking apps (Revolut, Stripe, Cash App).
- **Profile Settings Refinements**: Redesigned profile setting screens with hero header cards, segmented theme selectors, and organized grouped sections.
- **Automated GitHub Release Pipeline**: Integrated versioned APK artifact naming (`udharcard-merchant-app-v1.0.18-release.apk` & `udharcard-merchant-app-v1.0.18-debug.apk`) and automated uploads to GitHub Release `v1.0.18`.

---

## [1.0.17] - 2026-07-29

### 🚀 Core Production Features
- **One-Tap WhatsApp Payment Reminder**: Added direct WhatsApp payment collection button with personalized Hinglish message and dynamic UPI payment URL.
- **Phonebook Contact Import**: Integrated `flutter_contacts` to import customer name and 10-digit mobile number directly from device contacts.
- **Local Ledger Backup & Restore**: Built JSON export & restore capability for all customer credit ledgers, transactions, and merchant settings via `share_plus` and `file_picker`.

---

## [1.0.16] - 2026-07-29

### 🚀 Features & Enhancements
- **Merchant Profile Updates**: Added Google Drive Backup (Coming Soon) option, Merchant UPI Address management (persisted & used for dynamic payments), and direct Upload QR Code option. Removed Change Password option.
- **Voice Entry Fixes**: Fixed Android microphone permission (`RECORD_AUDIO`) and iOS permissions (`NSMicrophoneUsageDescription`), improved offline Hinglish/English NLP parsing (`"Ramesh 500 udhar diya"`), and added direct "Post to Udhar" button on voice transaction cards.
- **KYC Feature Documentation**: Created comprehensive step-by-step KYC architecture and workflow documentation (`docs/KYC_DOCUMENTATION.md`).

---

## [1.0.15] - 2026-07-28

### 🐛 Bug Fixes
- **Login Error Banner**: Fixed the issue where old login error messages persisted when opening the login screens or coming back to them. Added state clearing in `initState` and set up automatic error clearing as soon as the user starts correcting/typing their number.
- **Error Formatting**: Replaced raw Firebase exceptions (such as `[ TOO_SHORT ]`) with readable, user-friendly messages.

---

## [1.0.14] - 2026-07-28

### ✨ UI/UX Improvements
- **Numeric Keyboard & Constraints**: Restricted all mobile number input fields to open the numeric keyboard only. Enforced digits-only input and restricted length to exactly 10 digits to prevent users from accidentally typing country codes twice.

---

## [1.0.13] - 2026-07-28

### 🐛 Bug Fixes
- **OTP Login Buttons**: Fixed a bug where "Send OTP via SMS" and "Send OTP via WhatsApp" buttons remained in a disabled state when autofilling or copy-pasting numbers. Added direct text editing controller listeners to ensure buttons instantly enable on any input changes.

---

## [1.0.12] - 2026-07-28

### ✨ UI/UX Improvements
- **Auth Screens**: Redesigned the bottom navigation links (Login / Register) into touch-friendly, centered rows for a better user experience.
- **Registration Screen**: Added the '🇮🇳 +91' visual prefix to the phone input field, matching the login screen design.

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
