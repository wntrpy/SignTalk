const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

setGlobalOptions({ region: "us-central1" });
admin.initializeApp();
const db = admin.firestore();

/**
 * 🔔 Send FCM notification when a new message is created
 */
exports.sendChatNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const data = snap.data() || {};
    const messageReceiverId = data.receiverId; // Person receiving the message (Winter)
    const messageSenderId = data.senderId; // Person who sent the message (Chisa)
    const messageText = data.messageBody || "";

    if (!messageReceiverId || !messageSenderId) return null;

    // check mute status
    const chatDoc = await admin
      .firestore()
      .collection("chats")
      .doc(event.params.chatId)
      .get();
    const chatData = chatDoc.data();
    if (chatData?.mute && chatData.mute[messageReceiverId]) return null;

    // get receiver's FCM token (Winter's token)
    const userDoc = await db.collection("users").doc(messageReceiverId).get();
    if (!userDoc.exists) return null;
    const token = userDoc.data()?.fcmToken;
    if (!token) return null;

    // get sender's name (Chisa's name)
    const senderDoc = await db.collection("users").doc(messageSenderId).get();
    const senderName =
      senderDoc.exists && senderDoc.data().name
        ? senderDoc.data().name
        : "Someone";

    const notification = {
      title: senderName,
      body: messageText,
    };

    // FIXED: When Winter clicks the notification, she should see Chisa's chat
    // So receiverId in the payload should be Chisa's ID (the sender)
    const payloadData = {
      chatId: event.params.chatId,
      senderId: messageSenderId, // Chisa's ID
      receiverId: messageSenderId, // Also Chisa's ID - this is who Winter will chat with
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    };

    try {
      if (Array.isArray(token)) {
        await admin.messaging().sendMulticast({
          tokens: token,
          notification,
          data: payloadData,
        });
      } else {
        await admin.messaging().send({
          token,
          notification,
          data: payloadData,
        });
      }
      console.log("✅ Notification sent to:", messageReceiverId);
    } catch (err) {
      console.error("❌ Error sending notification:", err);
    }

    return null;
  }
);
