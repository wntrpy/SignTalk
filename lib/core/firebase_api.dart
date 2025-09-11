// lib/core/firebase_api.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  static Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[FirebaseApi] no current user — skipping saveFcmToken');
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    print('[FirebaseApi] FCM token for ${user.uid}: $token');

    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Listen for token refresh and update Firestore
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('[FirebaseApi] token refreshed for ${user.uid}: $newToken');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
