const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function to detect a Gas Leak and send a Push Notification (V2 Syntax).
 */
exports.onGasLeakDetected = onDocumentUpdated("hubs/{hubId}", async (event) => {
    // Get the data from before and after the update
    if (!event.data) {
        console.log("No data found in event. Exiting.");
        return null;
    }

    const change = event.data;
    const dataBefore = change.before.data();
    const dataAfter = change.after.data();
    const hubId = event.params.hubId; // Get hubId from event params

    // --- Main Logic ---
    if (dataBefore.gasLeak === false && dataAfter.gasLeak === true) {
        console.log(`Gas leak detected on hub: ${hubId}`);
        const ownerId = dataAfter.ownerId;
        if (!ownerId) {
            console.error("No ownerId found on the hub document.");
            return null;
        }

        // 2. Get the user's document
        const userDocRef = admin.firestore().collection("users").doc(ownerId);
        const userDoc = await userDocRef.get();

        if (!userDoc.exists) {
            console.error(`Owner document (users/${ownerId}) not found.`);
            return null;
        }

        const userData = userDoc.data();

        // --- Check if user wants notifications ---
        const gasLeakAlertsEnabled = userData.gasLeakAlerts ?? true;
        if (gasLeakAlertsEnabled === false) {
            console.log(`User ${ownerId} has disabled gas leak notifications. Skipping.`);
            return null;
        }
        // --- End of check ---

        // 3. Get the FCM token
        const fcmToken = userData.fcmToken;
        if (!fcmToken) {
            console.error(`FCM token not found for user: ${ownerId}.`);
            return null;
        }

        // 4. Construct the notification message payload
        const payload = {
            notification: {
                title: "GAS LEAK DETECTED!",
                body: "A potential gas leak has been detected from your Sentry Gas Hub. Please check immediately!",
                // 'sound' removed from here to fix the error
            },
            // Add Android specific config
            android: {
                notification: {
                    sound: "default",
                    priority: "high"
                }
            },
            // Add iOS specific config
            apns: {
                payload: {
                    aps: {
                        sound: "default"
                    }
                }
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                hubId: hubId,
                status: "GAS_LEAK",
            },
            token: fcmToken, // Specify the token directly for V2
        };

        // 5. Send the push notification
        try {
            console.log(`Sending notification to token: ${fcmToken}`);
            // Use admin.messaging().send() instead of sendToDevice()
            await admin.messaging().send(payload);
            console.log("Notification sent successfully.");
        } catch (error) {
            console.error("Error sending push notification:", error);
        }
    }
    return null; // Function finished
});