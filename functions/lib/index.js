"use strict";
/**
 * Firebase Cloud Functions for FinFlow
 *
 * This module contains Cloud Functions for secure Google IAP verification
 * and other backend operations for the FinFlow app.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminGrantPremium = exports.restorePremiumStatus = exports.verifyPurchase = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const googleapis_1 = require("googleapis");
// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
// Valid product IDs for FinFlow premium subscriptions
const VALID_PRODUCT_IDS = [
    'finflow_premium_monthly',
    'finflow_premium_yearly'
];
// Subscription durations in days
const SUBSCRIPTION_DURATIONS = {
    'finflow_premium_monthly': 30,
    'finflow_premium_yearly': 365
};
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
exports.verifyPurchase = functions.https.onCall(async (data, context) => {
    // Check if the user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to verify purchase.');
    }
    const userId = context.auth.uid;
    const { purchaseToken, productId, packageName } = data;
    // Validate input parameters
    if (!purchaseToken || !productId) {
        throw new functions.https.HttpsError('invalid-argument', 'purchaseToken and productId are required.');
    }
    // Validate productId is a known product
    if (!VALID_PRODUCT_IDS.includes(productId)) {
        throw new functions.https.HttpsError('invalid-argument', `Invalid product ID: ${productId}`);
    }
    try {
        // Verify the purchase with Google Play Developer API
        const isValid = await verifyWithGooglePlay(purchaseToken, productId, packageName);
        if (!isValid) {
            throw new functions.https.HttpsError('failed-precondition', 'Purchase verification failed. The purchase token may be invalid or expired.');
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
    }
    catch (error) {
        functions.logger.error('Error verifying purchase:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'An error occurred while verifying the purchase. Please try again.');
    }
});
/**
 * Verify a purchase token with Google Play Developer API
 */
async function verifyWithGooglePlay(purchaseToken, productId, packageName) {
    // Use the package name from environment or the one provided
    const appId = packageName || process.env.ANDROID_PACKAGE_NAME || 'com.finflow.app';
    try {
        // Get Google Play Developer API credentials
        // In production, you should set up a service account with proper credentials
        const auth = await googleapis_1.google.auth.getClient({
            scopes: ['https://www.googleapis.com/auth/androidpublisher']
        });
        const androidpublisher = googleapis_1.google.androidpublisher({
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
    }
    catch (error) {
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
function calculatePremiumExpiry(productId) {
    const daysToAdd = SUBSCRIPTION_DURATIONS[productId] || 30;
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + daysToAdd);
    return expiryDate.toISOString();
}
/**
 * Grant premium access to a user by updating their Firestore document
 */
async function grantPremiumAccess(userId, premiumData) {
    const userRef = db.collection('users').doc(userId);
    await userRef.update(Object.assign({}, premiumData));
}
/**
 * Check and restore premium status for a user
 * This function can be called to refresh premium status
 */
exports.restorePremiumStatus = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to restore premium status.');
    }
    const userId = context.auth.uid;
    const { purchaseToken, productId } = data;
    if (!purchaseToken || !productId) {
        throw new functions.https.HttpsError('invalid-argument', 'purchaseToken and productId are required.');
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
    }
    catch (error) {
        functions.logger.error('Error restoring premium status:', error);
        throw new functions.https.HttpsError('internal', 'An error occurred while restoring premium status.');
    }
});
/**
 * Admin function to manually grant premium access (for support purposes)
 * This function requires custom claims to be set for admin users
 */
exports.adminGrantPremium = functions.https.onCall(async (data, context) => {
    // Check if the caller is an admin
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    // Check for admin claim (you'll need to set this up in Firebase Auth)
    const userRecord = await admin.auth().getUser(context.auth.uid);
    const isAdmin = userRecord.customClaims && userRecord.customClaims.admin === true;
    if (!isAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Only administrators can grant premium access.');
    }
    const { userId, durationDays } = data;
    if (!userId || !durationDays || durationDays <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Valid userId and durationDays are required.');
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
    }
    catch (error) {
        functions.logger.error('Error granting admin premium:', error);
        throw new functions.https.HttpsError('internal', 'An error occurred while granting premium access.');
    }
});
//# sourceMappingURL=index.js.map