// Import necessary v2 Firebase modules
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Initialize the Firebase Admin SDK
initializeApp();

/**
 * Cloud Function to detect a Gas Leak and send a Push Notification (v2).
 */
exports.onGasLeakDetected = onDocumentUpdated("hubs/{hubId}", async (event) => {
    // Get the data from before and after the update
    // v2 uses event.data.before and event.data.after
    const dataBefore = event.data.before.data();
    const dataAfter = event.data.after.data();
    
    // Get the hubId from the event parameters
    const hubId = event.params.hubId;

    // --- Main Logic ---
    // Check if the 'gasLeak' field changed from 'false' to 'true'
    if (dataBefore.gasLeak === false && dataAfter.gasLeak === true) {
        console.log(`Gas leak detected on hub: ${hubId}`);

        // 1. Get the ownerId
        const ownerId = dataAfter.ownerId;
        if (!ownerId) {
            console.error("No ownerId found on the hub document. Notification cannot be sent.");
            return null;
        }

        // 2. Get the owner's user document to find their FCM token
        // Use getFirestore()
        const userDocRef = getFirestore().collection("users").doc(ownerId);
        const userDoc = await userDocRef.get();

        if (!userDoc.exists) {
            console.error(`Owner document (users/${ownerId}) not found.`);
            return null;
        }

        // 3. Get the FCM token
        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            console.error(`FCM token not found for user: ${ownerId}.`);
            return null;
        }

        // 4. Construct the notification message payload
        const payload = {
            notification: {
                title: "GAS LEAK DETECTED!",
                body: "A potential gas leak has been detected from your Sentry Gas Hub. Please check immediately!",
                sound: "default",
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                hubId: hubId,
                status: "GAS_LEAK",
            },
        };

        // 5. Send the push notification
        // Use getMessaging()
        try {
            console.log(`Sending notification to token: ${fcmToken}`);
            // Use getMessaging().sendToDevice()
            await getMessaging().sendToDevice(fcmToken, payload);
            console.log("Notification sent successfully.");
        } catch (error) {
            console.error("Error sending push notification:", error);
        }
    }
    return null; // Function finished
});