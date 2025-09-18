const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const functions = require("firebase-functions");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: process.env.GCLOUD_PROJECT,
});

exports.sendChatNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const data = snap.data() || {};
    const receiverId = data.receiverId;
    const senderId = data.senderId;
    const messageText = data.messageBody || "";

    if (!receiverId || !senderId) return null;
    console.log("Receiver:", receiverId, "Sender:", senderId);

    // check mute status in the chat doc
    const chatDoc = await admin
      .firestore()
      .collection("chats")
      .doc(event.params.chatId)
      .get();

    const chatData = chatDoc.data();
    if (chatData?.mute && chatData.mute[receiverId] === true) {
      console.log(
        `User ${receiverId} has muted this chat. Skipping notification.`
      );
      return null;
    }

    // get receiver’s FCM token
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(receiverId)
      .get();
    if (!userDoc.exists) return null;

    const userData = userDoc.data();
    const token = userData?.fcmToken;
    console.log("Token found:", token);

    if (!token) {
      console.log("No token for user", receiverId);
      return null;
    }

    // get sender’s name
    const senderDoc = await admin
      .firestore()
      .collection("users")
      .doc(senderId)
      .get();
    const senderName =
      senderDoc.exists && senderDoc.data().name
        ? senderDoc.data().name
        : "Someone";

    const notification = {
      title: senderName,
      body: messageText,
    };

    const payloadData = {
      chatId: event.params.chatId,
      senderId,
      receiverId,
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
      console.log("Notification sent to:", receiverId);
    } catch (err) {
      console.error("Error sending notification:", err);
    }

    return null;
  }
);
