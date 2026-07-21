# Changelog

## [Unreleased]
### Added
- Integrated Firebase Authentication (`firebase_core`, `firebase_auth`) for phone number OTP.
- Created `FirebasePhoneLoginScreen` for merchants to enter their phone number to receive OTP.
- Created `FirebaseOtpVerifyScreen` for OTP verification.
- Added "Login with Phone (OTP)" and "Register with Phone (OTP)" buttons on the respective login and register screens.
- Updated `auth_controller.dart` to handle sending and verifying Firebase OTP.
- Initialized Firebase in `main.dart`.
