const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

// Fire when a new message is created
exports.sendChatNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data(); // message document
    const receiverId = message.receiverId;
    const senderId = message.senderId;

    // get sender info
    const senderDoc = await admin
      .firestore()
      .collection("users")
      .doc(senderId)
      .get();
    const senderName = senderDoc.exists ? senderDoc.data().name : "Someone";

    // get receiver’s FCM token
    const receiverDoc = await admin
      .firestore()
      .collection("users")
      .doc(receiverId)
      .get();
    if (!receiverDoc.exists) return;
    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) return;

    const payload = {
      notification: {
        title: senderName,
        body: message.messageBody,
      },
      data: {
        chatId: event.params.chatId,
        senderId: senderId,
        receiverId: receiverId,
      },
    };

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("✅ Notification sent to", receiverId);
    } catch (e) {
      console.error("❌ Error sending notification:", e);
    }
  }
);
