const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");


admin.initializeApp();


exports.onGasLeakDetected = onDocumentUpdated("hubs/{hubId}", async (event) => {

    if (!event.data) {
        console.log("No data found in event. Exiting.");
        return null;
    }

    const change = event.data;
    const dataBefore = change.before.data();
    const dataAfter = change.after.data();
    const hubId = event.params.hubId; // Get hubId from event params


    if (dataBefore.gasLeak === false && dataAfter.gasLeak === true) {
        console.log(`Gas leak detected on hub: ${hubId}`);
        const ownerId = dataAfter.ownerId;
        if (!ownerId) {
            console.error("No ownerId found on the hub document.");
            return null;
        }


        const userDocRef = admin.firestore().collection("users").doc(ownerId);
        const userDoc = await userDocRef.get();

        if (!userDoc.exists) {
            console.error(`Owner document (users/${ownerId}) not found.`);
            return null;
        }

        const userData = userDoc.data();


        const gasLeakAlertsEnabled = userData.gasLeakAlerts ?? true;
        if (gasLeakAlertsEnabled === false) {
            console.log(`User ${ownerId} has disabled gas leak notifications. Skipping.`);
            return null;
        }



        const fcmToken = userData.fcmToken;
        if (!fcmToken) {
            console.error(`FCM token not found for user: ${ownerId}.`);
            return null;
        }


        const payload = {
            notification: {
                title: "GAS LEAK DETECTED!",
                body: "A potential gas leak has been detected from your Sentry Gas Hub. Please check immediately!",

            },

            android: {
                notification: {
                    sound: "default",
                    priority: "high"
                }
            },

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


        try {
            console.log(`Sending notification to token: ${fcmToken}`);

            await admin.messaging().send(payload);
            console.log("Notification sent successfully.");
        } catch (error) {
            console.error("Error sending push notification:", error);
        }
    }
    return null; // Function finished
});
