// lib/core/notification_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:signtalk/core/navigation.dart'; // exports `router`
import 'package:flutter/foundation.dart';

// Top-level background handler (must be top-level)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance =
      NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _handlePayloadNavigation(payload);
      },
    );

    // Create Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: 'Channel for chat messages',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Foreground messages -> show a local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final chatId = data['chatId'] ?? '';
      final receiverId = data['receiverId'] ?? '';
      final title =
          message.notification?.title ?? data['title'] ?? 'New message';
      final body = message.notification?.body ?? data['body'] ?? '';

      _local.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: '$chatId|$receiverId',
      );
    });

    // When the user taps a notification while the app is in background/foreground -> route
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessageNavigation(message);
    });

    // If the app was completely terminated and opened via notification:
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageNavigation(initialMessage);
    }

    if (kDebugMode) print('NotificationService initialized');
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final chatId = data['chatId'];
    final otherUserId = data['otherUserId']; // Changed
    if (chatId != null && otherUserId != null) {
      router.push(
        '/chat',
        extra: {'chatId': chatId, 'receiverId': otherUserId},
      );
    }
  }

  void _handlePayloadNavigation(String payload) {
    final parts = payload.split('|');
    if (parts.length >= 2) {
      final chatId = parts[0];
      final receiverId = parts[1];
      router.push('/chat', extra: {'chatId': chatId, 'receiverId': receiverId});
    }
  }
}
