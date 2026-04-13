import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token and save to backend
    await updateToken();

    // Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _saveTokenToBackend(newToken);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `await Firebase.initializeApp()` first.
    if (kDebugMode) {
      print("Handling a background message: ${message.messageId}");
    }
  }

  static Future<void> updateToken() async {
    if (kDebugMode) print('🔔 Attempting to get FCM Token...');
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        if (kDebugMode) print('🔔 FCM Token obtained.');
        await _saveTokenToBackend(token);
      } else {
        if (kDebugMode) print('🔔 FCM Token is NULL. Is google-services.json missing?');
      }
    } catch (e) {
      if (kDebugMode) print('🔔 Error getting FCM Token: $e');
    }
  }

  static Future<void> _saveTokenToBackend(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');
    final String? authToken = prefs.getString('auth_token');

    if (kDebugMode) print('🔔 Saving token for User: $userId');

    if (userId != null && authToken != null) {
      final result = await ApiService.updateFcmToken(
        userId: userId,
        fcmToken: fcmToken,
        token: authToken,
      );
      if (kDebugMode) print('🔔 Backend FCM update: ${result['success']}');
      if (!result['success']) {
        if (kDebugMode) print('🔔 Backend error: ${result['message']}');
      }
    } else {
      if (kDebugMode) print('🔔 userId or authToken missing in SharedPreferences');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }
}
