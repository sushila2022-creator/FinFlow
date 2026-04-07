# Test User Account for Google Play Review

## Overview
This document provides instructions for accessing FinFlow using a pre-configured test account. The test account is automatically created when the app starts and is always available for testing purposes.

## Test Credentials

**Email:** `appsmasters26@gmail.com`  
**Password:** `1234@5678`

## How to Use

1. **Launch the app** - The test account is automatically created in the background during app startup
2. **On the login screen**, enter the test credentials above
3. **Tap "Sign In"** - You will be logged in immediately without any email verification or OTP

## Important Notes

- **No Email Verification Required**: The test account is marked as verified in the system, so you won't need to verify your email address
- **No OTP or 2FA**: The account bypasses any two-factor authentication or phone verification
- **Always Available**: The test account is automatically recreated if it doesn't exist
- **No Interference**: This test account operates independently and won't affect any existing user accounts

## Technical Implementation

The test user functionality is implemented in `lib/services/test_user_service.dart` and integrated into the app startup in `lib/main.dart`. Key features:

- ✅ Runs silently in the background
- ✅ Does not block app startup
- ✅ Automatically creates account if missing
- ✅ Handles existing account gracefully
- ✅ No impact on normal user authentication flow
- ✅ Comprehensive error handling to prevent crashes

## Troubleshooting

If you encounter any issues logging in with the test account:

1. **Check internet connection** - The app requires internet for Firebase authentication
2. **Wait a few seconds** - The test account creation runs in the background and may take a moment
3. **Restart the app** - This will trigger the test account creation process again

## For Developers

To view debug logs related to test user creation, check the console output for messages prefixed with:
- `Test user does not exist, creating...`
- `Test user already exists`
- `Test user created successfully`
- `Test user credentials verified successfully`

## Security Note

This test account is intended solely for Google Play review and testing purposes. The credentials are hardcoded and should not be used in production environments.