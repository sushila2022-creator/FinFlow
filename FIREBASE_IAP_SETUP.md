# Firebase Backend Setup for Secure Google IAP Verification

This guide explains how to set up the Firebase backend for secure Google In-App Purchase (IAP) verification in the FinFlow app.

## Overview

The implementation consists of:

1. **Firebase Cloud Functions** - Server-side verification of Google Play purchases
2. **Updated Firestore Security Rules** - Prevent direct client updates to premium fields
3. **Updated Flutter App** - Uses Cloud Functions instead of direct Firestore writes

## Architecture

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Flutter App   │───▶│  Cloud Functions     │───▶│  Google Play API    │
│                 │   │  (verifyPurchase)    │   │                     │
└─────────────────┘    └──────────────────────┘    └─────────────────────┘
         │                        │
         │                        ▼
         │                ┌──────────────────────┐
         │                │      Firestore       │
         │                │  (update premium)    │
         │                └──────────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────────────────────────────────────┐
│              Firestore Security Rules            │
│  - Block client writes to premium fields        │
│  - Allow Cloud Functions (admin) to update      │
└─────────────────────────────────────────────────┘
```

## Setup Instructions

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Initialize Firebase Functions

```bash
cd functions
npm install
```

### 4. Configure Environment Variables

Set up environment variables for the Cloud Functions:

```bash
firebase functions:config:set \
  android.package_name="com.finflowai.money.manager"
```

### 5. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

### 6. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### 7. Update Flutter Dependencies

```bash
flutter pub get
```

## Google Play Console Setup

### 1. Create In-App Products

In Google Play Console, create the following subscription products:

- `finflow_premium_monthly` - Monthly premium subscription
- `finflow_premium_yearly` - Yearly premium subscription

### 2. Set Up Google Play Developer API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Enable the **Google Play Android Developer API**
4. Create a Service Account:
   - Go to **APIs & Services** > **Credentials**
   - Click **Create Credentials** > **Service Account**
   - Give it a name like "FinFlow IAP Verification"
5. Grant the service account access to your app in Google Play Console:
   - Go to **Users and permissions** in Google Play Console
   - Invite the service account email
   - Grant **View financial data** permission
6. Download the service account JSON key
7. Upload the JSON key to Firebase:
   ```bash
   firebase functions:secrets:set GOOGLE_APPLICATION_CREDENTIALS
   ```
   (Paste the contents of the JSON file when prompted)

## Security Rules

The Firestore security rules have been updated to:

1. **Allow users to read** their own user document
2. **Allow users to create** their user document but **block** premium fields
3. **Allow users to update** their user document but **block** premium fields
4. Premium fields can only be updated by Cloud Functions using the Admin SDK

### Protected Premium Fields

- `isPremium`
- `premiumExpiry`
- `purchaseToken`
- `premiumGrantedAt`
- `lastPurchaseToken`
- `premiumSource`
- `productId`

## Cloud Functions

### `verifyPurchase`

This is the main function called by the Flutter app after a purchase is made.

**Parameters:**
- `purchaseToken` (string) - The purchase token from Google Play
- `productId` (string) - The product ID that was purchased

**Returns:**
```json
{
  "success": true,
  "message": "Premium access granted successfully!",
  "premiumExpiry": "2026-05-02T17:00:00.000Z",
  "productId": "finflow_premium_monthly"
}
```

### `restorePremiumStatus`

This function can be called to verify and restore premium status.

**Parameters:**
- `purchaseToken` (string) - The original purchase token
- `productId` (string) - The product ID

### `adminGrantPremium`

An admin function to manually grant premium access (for support purposes).

**Parameters:**
- `userId` (string) - The user ID to grant premium to
- `durationDays` (number) - Number of days for the premium

**Note:** This function requires the caller to have the `admin` custom claim.

## Testing

### Development Mode

The Cloud Functions include a development mode that allows test purchases to succeed without actual Google Play verification. This is enabled when:

- `NODE_ENV=development` or
- `FIREBASE_EMULATOR_MODE=true`

### Testing the Flow

1. Run the Flutter app in debug mode
2. Navigate to the Premium screen
3. Select a subscription plan
4. Complete the purchase flow (use test card in Google Play)
5. The app will call the Cloud Function to verify the purchase
6. Check Firestore to verify the user's premium status was updated

### Testing with Emulator

```bash
# Start Firebase emulators
firebase emulators:start

# In another terminal, run the Flutter app with emulator connection
export FIREBASE_FUNCTIONS_EMULATOR_URL="http://localhost:5001"
flutter run
```

## Troubleshooting

### Common Issues

1. **"Function not found" error**
   - Ensure functions are deployed: `firebase deploy --only functions`
   - Check the function name matches exactly

2. **"Permission denied" error**
   - Ensure user is authenticated
   - Check Firestore security rules are deployed

3. **"Purchase verification failed" error**
   - Check the purchase token is valid
   - Verify product ID matches the configured IDs
   - In production, ensure Google Play API credentials are set up

4. **"Network error" or timeout**
   - Check internet connection
   - Verify Firebase project is properly configured

### Debug Logs

View Cloud Function logs:

```bash
firebase functions:log
```

## Production Considerations

### 1. Security

- Never expose service account credentials in client code
- Always verify purchases server-side (which we do with Cloud Functions)
- Use Firebase App Check for additional security

### 2. Reliability

- Implement retry logic for failed verifications
- Consider using Cloud Tasks for reliable processing
- Set up monitoring and alerts for failed verifications

### 3. Subscription Management

- Handle subscription renewals
- Handle subscription cancellations and refunds
- Implement grace periods for expired subscriptions

### 4. Testing

- Use Google Play's license test accounts
- Test with real purchases in a staging environment
- Implement proper error handling and user feedback

## File Structure

```
FinFlow/
├── functions/
│   ├── src/
│   │   └── index.ts          # Cloud Functions code
│   ├── package.json          # Functions dependencies
│   └── tsconfig.json         # TypeScript config
├── lib/
│   ├── models/
│   │   └── user_model.dart   # Updated with premium fields
│   └── services/
│       └── iap_service.dart  # Updated to use Cloud Functions
├── firebase.json             # Firebase configuration
├── firestore.rules           # Updated security rules
├── firestore.indexes.json    # Firestore indexes
└── pubspec.yaml              # Added cloud_functions dependency
```

## Migration from Direct Firestore Writes

If you have existing code that directly writes premium status to Firestore, you should:

1. Remove direct Firestore writes for premium fields
2. Update to use the Cloud Function approach
3. Deploy the updated security rules
4. Test thoroughly before releasing

## Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)