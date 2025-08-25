import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize FCM
  Future<void> initNotifications() async {
    // Request permission
    await _firebaseMessaging.requestPermission();

    // Get token
    final fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");

    // TODO: Save this token to Firestore under the logged-in user’s document
  }

  // Handle messages when the app is in foreground
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // Example: Navigate to chat screen when notification tapped
    // You can include receiverId in `message.data`
  }

  // Listen for messages
  void initListeners() {
    FirebaseMessaging.onMessage.listen((message) {
      print("Got foreground message: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
