import 'dart:convert';
import 'dart:io' show Platform, HttpClient, File;
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'FCM Background message received: ${message.messageId} - ${message.data}',
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'abrp_announcements';
  static const String channelName = 'ABRP Wishes & Announcements';
  static const String channelDesc =
      'Festival greetings, birthday and anniversary wishes, and community notices.';

  bool _isInitialized = false;
  String? _lastRegisteredToken;

  /// Global callback for when a notification is tapped to navigate inside the app
  Function(Map<String, dynamic> data)? onNotificationTapped;

  Future<void> initialize({Dio? dio}) async {
    if (_isInitialized) return;

    try {
      // 1. Request OS notification permissions (Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 2. Initialize Flutter Local Notifications for rich foreground popups
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotif.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data =
                  jsonDecode(response.payload!) as Map<String, dynamic>;
              onNotificationTapped?.call(data);
            } catch (e) {
              debugPrint('Error parsing notification payload: $e');
            }
          }
        },
      );

      // 3. Create high-importance Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // 4. Foreground notification presentation options on iOS & Android
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Handle foreground message presentation via local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'FCM Foreground message received: ${message.notification?.title}',
        );
        _showLocalNotification(message);
      });

      // 6. Handle notification click when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Message opened from background: ${message.data}');
        onNotificationTapped?.call(message.data);
      });

      // 7. Check for initial message if app was terminated and opened via notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM Initial message launch: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 800), () {
          onNotificationTapped?.call(initialMessage.data);
        });
      }

      // 8. Register FCM token whenever token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        registerDeviceTokenWithBackend(newToken, dio: dio);
      });

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  Future<String?> _downloadAndSaveImage(String url, String filename) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading notification image: $e');
      return null;
    }
  }

  /// Displays a rich local notification banner with image support when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notif = message.notification;
      final data = message.data;
      final title = notif?.title ?? data['title'] ?? 'ABRP Samaj';
      final body = notif?.body ?? data['body'] ?? '';
      final imageUrl =
          notif?.android?.imageUrl ?? data['imageUrl'] ?? data['posterUrl'];

      BigPictureStyleInformation? bigPictureStyleInformation;
      String? localImagePath;

      if (imageUrl != null && imageUrl.toString().trim().isNotEmpty) {
        localImagePath = await _downloadAndSaveImage(
          imageUrl.toString().trim(),
          'notif_${message.hashCode}.jpg',
        );
        if (localImagePath != null) {
          bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(localImagePath),
            largeIcon: FilePathAndroidBitmap(localImagePath),
            contentTitle: title,
            summaryText: body.isNotEmpty ? body : null,
            hideExpandedLargeIcon: true,
          );
        }
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: bigPictureStyleInformation,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: localImagePath != null
            ? [DarwinNotificationAttachment(localImagePath)]
            : null,
      );

      await _localNotif.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Retrieves current device FCM token and registers it on the backend
  Future<void> registerDeviceTokenWithBackend(String? token, {Dio? dio}) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      if (fcmToken == _lastRegisteredToken) return;

      const storage = FlutterSecureStorage();
      final jwt = await storage.read(key: AppConstants.tokenKey);
      if (jwt == null || jwt.isEmpty) {
        debugPrint('User not logged in yet. FCM token cached until login.');
        return;
      }

      final client =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.baseUrl,
              headers: {
                'Authorization': 'Bearer $jwt',
                'Content-Type': 'application/json',
              },
            ),
          );

      final deviceType = Platform.isIOS ? 'ios' : 'android';
      await client.post(
        'notifications/register',
        data: {'fcmToken': fcmToken, 'deviceType': deviceType},
      );

      _lastRegisteredToken = fcmToken;
      debugPrint(
        '✅ FCM token registered with backend successfully ($deviceType).',
      );
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
    }
  }

  /// Purges token from backend on logout
  Future<void> unregisterDeviceToken({Dio? dio}) async {
    try {
      final fcmToken = await _fcm.getToken();
      if (fcmToken == null) return;

      const storage = FlutterSecureStorage();
      final jwt = await storage.read(key: AppConstants.tokenKey);
      if (jwt == null) return;

      final client =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.baseUrl,
              headers: {
                'Authorization': 'Bearer $jwt',
                'Content-Type': 'application/json',
              },
            ),
          );

      await client.post(
        'notifications/unregister',
        data: {'fcmToken': fcmToken},
      );
      _lastRegisteredToken = null;
      debugPrint('FCM token unregistered from backend.');
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }
}
