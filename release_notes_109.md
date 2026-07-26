✨ *What's New in UdharCard Merchant v1.0.9!*

🔐 *Persistent Session & Logout Bug Fix*
- Resolved issue where merchants were getting redirected back to LoginScreen after 2-3 minutes of activity.
- Configured persistent session storage for Firebase Auth & OTP login tokens.
- Updated network error handler to prevent background 401 HTTP errors from kicking authenticated merchants out of the app.
