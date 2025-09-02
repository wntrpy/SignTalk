import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

//TODO: continue - push notif
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

  // handle messages when the app is in foreground
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
  }

  // listen for messages
  void initListeners() {
    FirebaseMessaging.onMessage.listen((message) {
      print("Got foreground message: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
