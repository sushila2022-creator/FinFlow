/**
 * Firebase Cloud Functions for FinFlow
 * 
 * This module contains Cloud Functions for secure Google IAP verification
 * and other backend operations for the FinFlow app.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {google} from 'googleapis';

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

// Valid product IDs for FinFlow premium subscriptions
const VALID_PRODUCT_IDS = [
  'finflow_premium_monthly',
  'finflow_premium_yearly'
];

// Subscription durations in days
const SUBSCRIPTION_DURATIONS: {[key: string]: number} = {
  'finflow_premium_monthly': 30,
  'finflow_premium_yearly': 365
};

/**
 * Interface for the verifyPurchase callable function request
 */
interface VerifyPurchaseRequest {
  purchaseToken: string;
  productId: string;
  packageName?: string;
}

/**
 * Interface for the verifyPurchase response
 */
interface VerifyPurchaseResponse {
  success: boolean;
  message: string;
  premiumExpiry?: string;
  productId?: string;
}

/**
 * Verify a Google Play purchase token with Google's API
 * and grant premium access if valid.
 * 
 * This function:
 * 1. Validates the purchase token with Google Play Developer API
 * 2. Checks if the productId is valid
 * 3. Updates the user's Firestore document with premium status
 * 4. Returns the result to the client
 */
export const verifyPurchase = functions.https.onCall(
  async (data: VerifyPurchaseRequest, context): Promise<VerifyPurchaseResponse> => {
    // Check if the user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to verify purchase.'
      );
    }

    const userId = context.auth.uid;
    const { purchaseToken, productId, packageName } = data;

    // Validate input parameters
    if (!purchaseToken || !productId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'purchaseToken and productId are required.'
      );
    }

    // Validate productId is a known product
    if (!VALID_PRODUCT_IDS.includes(productId)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid product ID: ${productId}`
      );
    }

    try {
      // Verify the purchase with Google Play Developer API
      const isValid = await verifyWithGooglePlay(purchaseToken, productId, packageName);

      if (!isValid) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Purchase verification failed. The purchase token may be invalid or expired.'
        );
      }

      // Calculate premium expiry date
      const expiryDate = calculatePremiumExpiry(productId);

      // Update user's premium status in Firestore
      await grantPremiumAccess(userId, {
        isPremium: true,
        premiumExpiry: expiryDate,
        purchaseToken: purchaseToken,
        premiumGrantedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastPurchaseToken: purchaseToken,
        premiumSource: 'google_play',
        productId: productId
      });

      functions.logger.info(`Premium access granted to user ${userId}`, {
        userId,
        productId,
        premiumExpiry: expiryDate
      });

      return {
        success: true,
        message: 'Premium access granted successfully!',
        premiumExpiry: expiryDate,
        productId: productId
      };

    } catch (error) {
      functions.logger.error('Error verifying purchase:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'An error occurred while verifying the purchase. Please try again.'
      );
    }
  }
);

/**
 * Verify a purchase token with Google Play Developer API
 */
async function verifyWithGooglePlay(
  purchaseToken: string, 
  productId: string, 
  packageName?: string
): Promise<boolean> {
  // Use the package name from environment or the one provided
  const appId = packageName || process.env.ANDROID_PACKAGE_NAME || 'com.finflowai.money.manager';

  try {
    // Get Google Play Developer API credentials
    // In production, you should set up a service account with proper credentials
    const auth = await google.auth.getClient({
      scopes: ['https://www.googleapis.com/auth/androidpublisher']
    });

    const androidpublisher = google.androidpublisher({
      version: 'v3',
      auth: auth
    });

    // Call Google Play Developer API to verify the purchase
    const response = await androidpublisher.purchases.subscriptionsv2.get({
      packageName: appId,
      token: purchaseToken
    });

    const subscription = response.data;

    // Check if the subscription is active
    if (!subscription) {
      functions.logger.warn('No subscription data returned from Google Play');
      return false;
    }

    // Verify the productId matches
    if (subscription.lineItems && subscription.lineItems.length > 0) {
      const lineItem = subscription.lineItems[0];
      if (lineItem.productId !== productId) {
        functions.logger.warn(`Product ID mismatch: expected ${productId}, got ${lineItem.productId}`);
        return false;
      }
    }

    // Check subscription state
    // State 1 = Active, State 2 = Expired, State 3 = In grace period, etc.
    const subscriptionState = subscription.subscriptionState;
    if (subscriptionState !== '1' && subscriptionState !== '3') {
      functions.logger.warn(`Subscription is not active. State: ${subscriptionState}`);
      return false;
    }

    return true;

  } catch (error) {
    functions.logger.error('Error verifying with Google Play:', error);
    
    // For development/testing, you might want to allow test purchases
    // Remove this in production
    if (process.env.NODE_ENV === 'development' || process.env.FIREBASE_EMULATOR_MODE) {
      functions.logger.warn('Running in development mode - allowing test purchase');
      return true;
    }

    return false;
  }
}

/**
 * Calculate premium expiry date based on product ID
 */
function calculatePremiumExpiry(productId: string): string {
  const daysToAdd = SUBSCRIPTION_DURATIONS[productId] || 30;
  const expiryDate = new Date();
  expiryDate.setDate(expiryDate.getDate() + daysToAdd);
  return expiryDate.toISOString();
}

/**
 * Grant premium access to a user by updating their Firestore document
 */
async function grantPremiumAccess(
  userId: string, 
  premiumData: {[key: string]: any}
): Promise<void> {
  const userRef = db.collection('users').doc(userId);

  await userRef.update({
    ...premiumData
  });
}

/**
 * Check and restore premium status for a user
 * This function can be called to refresh premium status
 */
export const restorePremiumStatus = functions.https.onCall(
  async (data: { purchaseToken: string; productId: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to restore premium status.'
      );
    }

    const userId = context.auth.uid;
    const { purchaseToken, productId } = data;

    if (!purchaseToken || !productId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'purchaseToken and productId are required.'
      );
    }

    try {
      // Verify the purchase with Google Play
      const isValid = await verifyWithGooglePlay(purchaseToken, productId);

      if (!isValid) {
        // If verification fails, remove premium status
        await db.collection('users').doc(userId).update({
          isPremium: false,
          premiumExpiry: null,
          purchaseToken: null
        });

        return {
          success: false,
          message: 'Premium subscription has expired or is no longer valid.'
        };
      }

      // Update premium expiry
      const expiryDate = calculatePremiumExpiry(productId);
      await db.collection('users').doc(userId).update({
        isPremium: true,
        premiumExpiry: expiryDate,
        purchaseToken: purchaseToken,
        productId: productId
      });

      return {
        success: true,
        message: 'Premium status restored.',
        premiumExpiry: expiryDate
      };

    } catch (error) {
      functions.logger.error('Error restoring premium status:', error);
      throw new functions.https.HttpsError(
        'internal',
        'An error occurred while restoring premium status.'
      );
    }
  }
);

/**
 * Admin function to manually grant premium access (for support purposes)
 * This function requires custom claims to be set for admin users
 */
export const adminGrantPremium = functions.https.onCall(
  async (data: { userId: string; durationDays: number }, context) => {
    // Check if the caller is an admin
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated.'
      );
    }

    // Check for admin claim (you'll need to set this up in Firebase Auth)
    const userRecord = await admin.auth().getUser(context.auth.uid);
    const isAdmin = userRecord.customClaims && (userRecord.customClaims as any).admin === true;

    if (!isAdmin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only administrators can grant premium access.'
      );
    }

    const { userId, durationDays } = data;

    if (!userId || !durationDays || durationDays <= 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Valid userId and durationDays are required.'
      );
    }

    try {
      const expiryDate = new Date();
      expiryDate.setDate(expiryDate.getDate() + durationDays);

      await db.collection('users').doc(userId).update({
        isPremium: true,
        premiumExpiry: expiryDate.toISOString(),
        premiumGrantedAt: admin.firestore.FieldValue.serverTimestamp(),
        premiumSource: 'admin_grant'
      });

      functions.logger.info(`Admin granted premium to user ${userId} for ${durationDays} days`);

      return {
        success: true,
        message: `Premium access granted for ${durationDays} days.`,
        premiumExpiry: expiryDate.toISOString()
      };

    } catch (error) {
      functions.logger.error('Error granting admin premium:', error);
      throw new functions.https.HttpsError(
        'internal',
        'An error occurred while granting premium access.'
      );
    }
  }
);