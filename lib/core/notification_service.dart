import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/router.dart';
import 'package:go_router/go_router.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Handling background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;

    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp();

      // 2. Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup Local Notifications (for Foreground popups)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      
      await _localNotif.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            _handleNotificationTap(details.payload!);
          }
        },
      );

      // Create High Importance Channel for Android explicitly
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // Match AndroidManifest.xml
        'High Importance Notifications',
        description: 'This channel is used for important push notifications.',
        importance: Importance.max,
      );
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Request Permissions
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Token Refresh Listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print("🔄 FCM Token Refreshed: $newToken");
        // We sync the new token with the backend if the user is logged in
        // Note: In a real app, you'd check if the user is authenticated here
        // For now, we rely on the next registerDevice call or manual sync
      });

      // 6. Push Message Streams
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
         _handleNotificationTap(message.data['path'] ?? '/home');
      });

      // 7. Check if app was opened from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data['path'] ?? '/home');
      }

      _isInitialized = true;
      print("🚀 Notification Service Initialized Successfully");
    } catch (e) {
      print("❌ Error initializing NotificationService: $e");
    }
  }

  /// Central handler for notification taps (Deep Linking)
  void _handleNotificationTap(String path) {
    if (navigatorKey.currentContext == null) {
      print("⚠️ No context available for navigation");
      return;
    }
    
    print("🎯 Navigating to: $path");
    try {
      GoRouter.of(navigatorKey.currentContext!).push(path);
    } catch (e) {
      print("❌ Navigation error: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print("🔔 Foreground message received: ${message.notification?.title}");
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<String?> getFCMToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          print("⚠️ FCM token fetch timed out");
          return "";
        },
      );
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  /// Static helper to register the device token with the backend
  static Future<void> registerDevice(String authToken) async {
    if (kIsWeb) return;
    try {
      final token = await NotificationService().getFCMToken();
      if (token != null) {
        final api = ApiService();
        await api.updateFcmToken(authToken, token);
        print("✅ Device registered for push notifications.");
      }
    } catch (e) {
      print("❌ Failed to register device: $e");
    }
  }
}
