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

  /// Key the last known FCM token is cached under, so checkout can stamp it on a guest
  /// order without waiting on Firebase.
  static const String _prefsKey = 'fcm_token';

  /// The last FCM token this device was issued, or null before one has been obtained.
  ///
  /// A guest order carries this value to the server, because a guest has no user row for
  /// the token to live on - it is the only way an order update can reach their phone.
  static Future<String?> cachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Stores the token where it can be reached without Firebase, then tells the server.
  ///
  /// Which server call depends on who is using the app: a signed-in customer's token goes
  /// on their user row, while a guest's is written onto the orders they placed from this
  /// device. Firebase reissues tokens on reinstall, restore and its own schedule, so
  /// without the guest branch the token stamped at checkout goes stale and their pushes
  /// stop arriving with nothing to show that they did.
  static Future<void> _saveTokenToBackend(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, fcmToken);

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
      return;
    }

    // Signed out: the device token in the request header is what identifies the orders to
    // update, so this can only ever touch orders placed from this device.
    final result = await ApiService.updateGuestFcmToken(fcmToken: fcmToken);
    if (kDebugMode) {
      print('🔔 Guest FCM update: ${result['success']} (${result['data']})');
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
