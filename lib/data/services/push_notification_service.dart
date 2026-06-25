import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hostelx_high_importance',
    'HostelX Notifications',
    description: 'Booking, payment, complaint, and system notifications.',
    importance: Importance.high,
  );

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize({bool requestPermission = false}) async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (requestPermission) {
      await _requestPermission();
    }
    await _initializeLocalNotifications();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<void> registerUser(String userId) async {
    if (userId.trim().isEmpty) return;

    try {
      // Ensure initialized and permissions are requested
      await initialize();
      await _requestPermission();

      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(userId, token);
        debugPrint('FCM token saved for user $userId');
      } else {
        debugPrint('FCM token is null for user $userId');
      }

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        await _saveToken(userId, newToken);
        debugPrint('FCM token refreshed for user $userId');
      });
    } catch (e) {
      debugPrint('FCM registration failed for user $userId: $e');
    }
  }

  Future<void> unregisterUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      if (userId.trim().isEmpty) return;

      // Remove current token if possible, or just clear fcmToken field
      final data = {
        'fcmToken': '',
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (token != null) {
        data['fcmTokens'] = FieldValue.arrayRemove([token]);
      }

      await _db.collection('users').doc(userId).update(data);
    } catch (e) {
      debugPrint('FCM unregister failed for user $userId: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(settings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _saveToken(String userId, String token) {
    return _db.collection('users').doc(userId).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];

    if (title == null && body == null) return;

    try {
      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'],
      );
    } catch (e) {
      debugPrint('Foreground notification skipped: $e');
    }
  }
}
