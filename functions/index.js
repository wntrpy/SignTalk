const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const speech = require("@google-cloud/speech").v1p1beta1;

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
    const receiverId = data.receiverId;
    const senderId = data.senderId;
    const messageText = data.messageBody || "";

    if (!receiverId || !senderId) return null;

    // check mute status
    const chatDoc = await admin
      .firestore()
      .collection("chats")
      .doc(event.params.chatId)
      .get();
    const chatData = chatDoc.data();
    if (chatData?.mute && chatData.mute[receiverId]) return null;

    // get receiver’s FCM token
    const userDoc = await db.collection("users").doc(receiverId).get();
    if (!userDoc.exists) return null;
    const token = userDoc.data()?.fcmToken;
    if (!token) return null;

    // get sender’s name
    const senderDoc = await db.collection("users").doc(senderId).get();
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
      console.log("✅ Notification sent to:", receiverId);
    } catch (err) {
      console.error("❌ Error sending notification:", err);
    }

    return null;
  }
);

/**
 * 🎤 Transcribe uploaded audio to text using Google Speech-to-Text
 */
exports.transcribeAudio = onObjectFinalized(async (event) => {
  const object = event.data;
  if (!object || !object.contentType.startsWith("audio/")) return;

  const bucketName = object.bucket;
  const filePath = object.name;
  const gcsUri = `gs://${bucketName}/${filePath}`;
  const audioUrl = `https://storage.googleapis.com/${bucketName}/${filePath}`;

  const client = new speech.SpeechClient();

  const request = {
    audio: { uri: gcsUri },
    config: {
      encoding: "MPEG4", // Fixed encoding for .m4a AAC
      sampleRateHertz: 44100, // match your recording
      languageCode: "en-US",
      audioChannelCount: 1,
      enableAutomaticPunctuation: true,
    },
  };

  try {
    const [response] = await client.recognize(request);
    const transcription = response.results
      .map((r) => r.alternatives[0].transcript)
      .join(" ")
      .trim();

    console.log(`📝 Transcription: ${transcription || "[no speech detected]"}`);

    // Update all messages that reference this audio URL
    const snapshot = await db
      .collectionGroup("messages")
      .where("audioUrl", "==", audioUrl)
      .get();

    if (snapshot.empty) {
      console.log("⚠️ No messages found for this audioUrl");
      return;
    }

    snapshot.forEach((doc) => {
      doc.ref.update({
        messageBody: transcription || "[no speech detected]",
        status: "sent",
      });
    });
  } catch (err) {
    console.error("❌ Speech-to-Text error:", err);
  }
});
