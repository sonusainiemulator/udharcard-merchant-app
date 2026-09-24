# 📱 UdharCard Merchant: Notification Architecture & Admin Action Guide

This document outlines the complete notification lifecycle, admin subscription events, account suspension handling, and real-time triggers for the **UdharCard Merchant Mobile Application**.

---

## 1. ⚙️ Admin Subscription Plan Events & App Behavior

| Event | Admin Action | Merchant App Impact & Notification |
| :--- | :--- | :--- |
| **Plan Pricing / Features Update** | Admin updates price, trial days, or feature list in `/admin/subscriptions/plans`. | **Live Dynamic Sync**: No disruptive push notification is sent. Whenever the merchant opens or refreshes the **Choose Plan** screen, the app fetches live rates and active features via `/api/subscription/plans`. |
| **Offline Upgrade Request Approved** | Admin reviews bank/QR payment and clicks **Approve** in `/admin/subscriptions/requests`. | **Instant Feature Unlock**: Merchant subscription status transitions to `active`. AI Voice Khata, unlimited customer ledger entries, and Soundbox voice alerts activate immediately. |
| **Offline Upgrade Request Rejected** | Admin clicks **Reject** with an optional admin remark. | **Status Update**: Upgrade status screen updates to `Rejected` displaying the admin remark. |
| **Free Trial Extension (`extendTrial`)** | Admin extends trial duration (1–90 days) for a merchant. | **Uninterrupted Access**: `trial_ends_at` date is extended in database; merchant continues using AI Voice Khata without encountering trial expiry paywalls. |
| **Direct Plan Assignment (`assignPlan`)** | Admin manually switches a merchant between Basic, Premium, or Gold plans. | **Immediate Profile Re-sync**: Plan code and renewal timestamp update instantly on next API handshake. |

---

## 2. 🚫 Admin Merchant Suspension / Blocking Lifecycle

When an administrator changes a merchant's status to **Suspended / Inactive (`status = 0`)** from the Admin Panel:

1. **API Interception**: On the very next API request, `VerifyUserApi` detects `$user->status == 0` and blocks execution with `'Your account has been suspend'`.
2. **Session Termination**: `ApiStatus.checkStatus()` in the app automatically wipes the stored token from encrypted Hive local storage (`HiveHelp.remove(Keys.token)`).
3. **Screen Eviction**: Merchant is forcibly logged out and redirected to the **Login Screen**.
4. **Re-login Guard**: Future login attempts are rejected at the authentication gateway with the suspension notice.
5. **Direct Email Communication**: The admin can dispatch an explanatory email via `/admin/user/send-email/{id}`.

---

## 3. 🔔 Complete Merchant Notification Master List

### Category A: Real-Time Payments & Soundbox Voice Alerts
| # | Event | Channel | Soundbox Voice Alert | App Impact |
| :-: | :--- | :--- | :-: | :--- |
| **1** | **Customer QR Payment Received** | Pusher Socket + Local Push | **Yes** (*"UdharCard par ₹X prapt hue"*) | Screen balance and ledger sync in real-time without manual refresh. |
| **2** | **Customer Udhar Settlement** | Pusher Socket + In-App Bell | No | Ledger entry is marked paid and outstanding balance updates automatically. |

### Category B: Subscription & Trial Lifecycle
| # | Event | Channel | In-App Impact |
| :-: | :--- | :--- | :--- |
| **3** | **7-Day Free Trial Activation** | In-App Confirmation Banner | Confirms activation and displays remaining trial countdown. |
| **4** | **Trial / Subscription Expiry Guard** | In-App Modal Alert | Tapping Voice Khata mic triggers *"Free Trial Expired - Upgrade to Premium"* paywall. |
| **5** | **Offline Payment Resolution** | In-App Status Screen | Reflects Approved/Rejected status with admin remarks. |

### Category C: Security, OTP & Account Management
| # | Event | Channel | In-App Impact |
| :-: | :--- | :--- | :--- |
| **6** | **Mobile Login OTP** | SMS Gateway | 6-digit OTP delivered for fast login / password recovery. |
| **7** | **Email Verification Code** | Email Gateway | 6-digit verification code sent during signup or email update. |
| **8** | **Account Suspension Notice** | Screen Alert + Auto-Logout | Forces session termination and blocks app access. |
| **9** | **2FA Security Challenge** | Push / Authenticator | Required when Two-Factor Authentication is active. |
| **10** | **KYC Document Status** | In-App Profile Status | Alerts merchant when Identity/Address proof is approved or needs re-submission. |

### Category D: Payouts & Finance
| # | Event | Channel | In-App Impact |
| :-: | :--- | :--- | :--- |
| **11** | **Payout Request Submitted** | In-App Toast | Confirms wallet withdrawal request logged with admin. |
| **12** | **Payout Processed / Rejected** | In-App History + Push | Confirms transfer to merchant bank account or details rejection reason. |

### Category E: Customer Support
| # | Event | Channel | In-App Impact |
| :-: | :--- | :--- | :--- |
| **13** | **Admin Reply on Support Ticket** | In-App Ticket Thread | Alerts merchant of an update on their open support query. |

### Category F: Outgoing Payment Reminders (Merchant to Customer)
| # | Event | Channel | Customer Impact |
| :-: | :--- | :--- | :--- |
| **14** | **Payment Due Reminder** | Push Notification + SMS + WhatsApp | Customer receives personalized reminder with deep-linked UPI payment URL. |
