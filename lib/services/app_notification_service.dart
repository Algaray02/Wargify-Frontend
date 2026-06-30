import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargify/core/constants/api_endpoints.dart';
import 'package:wargify/firebase_options.dart';
import 'package:wargify/screens/common/notifikasi/notifikasi_log_screen.dart';
import 'package:wargify/screens/common/sos/sos_detail_screen.dart';
import 'package:wargify/screens/rt/sos/sos_dashboard_screen.dart';
import 'package:wargify/services/api_service.dart';
import 'package:wargify/services/secure_session_storage.dart';
import 'package:wargify/services/session_expiry_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class AppNotificationService {
  AppNotificationService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  static const _enabledKey = 'push_notifications_enabled';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'wargify_notifications',
        'Wargify Notifications',
        description: 'Notifikasi aktivitas Wargify',
        importance: Importance.high,
      );

  static final AndroidNotificationChannel _sosChannel =
      AndroidNotificationChannel(
        'wargify_sos_alerts',
        'Wargify SOS Alerts',
        description: 'Notifikasi darurat SOS prioritas tinggi',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('sos_alert'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 900, 180, 900, 180, 1300]),
      );

  final ApiService _apiService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize({bool registerToken = false}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_sosChannel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) async {
      if (await isPushEnabled()) {
        await _showForegroundNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRemoteMessageTap(initialMessage);
      });
    }

    _messaging.onTokenRefresh.listen((token) async {
      if (await isPushEnabled()) {
        await _registerTokenSafely(token);
      }
    });

    if (registerToken && await isPushEnabled()) {
      final token = await _messaging.getToken();
      await _registerTokenSafely(token);
    }
  }

  Future<bool> isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      final token = await _messaging.getToken();
      await _registerTokenSafely(token);
    }
  }

  Future<void> registerFcmToken(String token) async {
    if (token.trim().isEmpty) return;
    await _apiService.patch(ApiEndpoints.fcmToken, {'fcm_token': token.trim()});
  }

  Future<void> _registerTokenSafely(String? token) async {
    if (token == null || token.trim().isEmpty) return;
    try {
      await registerFcmToken(token);
    } catch (_) {}
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Wargify';
    final body =
        notification?.body ?? message.data['body'] ?? 'Notifikasi baru';
    final isSos = message.data['type'] == 'sos';
    final channel = isSos ? _sosChannel : _androidChannel;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: isSos ? Importance.max : Importance.high,
          priority: isSos ? Priority.max : Priority.high,
          icon: '@mipmap/launcher_icon',
          sound: isSos
              ? const RawResourceAndroidNotificationSound('sos_alert')
              : null,
          category: isSos
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.status,
          fullScreenIntent: isSos,
          playSound: true,
          enableVibration: true,
          vibrationPattern: isSos
              ? Int64List.fromList([0, 900, 180, 900, 180, 1300])
              : null,
          ticker: isSos ? 'DARURAT SOS' : null,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _handleNotificationData(Map<String, dynamic>.from(message.data));
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _handleNotificationData(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    final navigator = SessionExpiryHandler.navigatorKey.currentState;
    if (navigator == null) return;

    final user = await SecureSessionStorage().getUserData();
    final role = user?['role']?.toString();
    final type = data['type']?.toString();

    Widget page;
    if (type == 'sos') {
      final alertId = data['alert_id']?.toString() ?? '';
      if (role == 'KETUA_RT') {
        page = const SosDashboardScreen();
      } else if (alertId.isNotEmpty) {
        page = SosDetailScreen(alertId: alertId);
      } else {
        page = const NotifikasiLogScreen();
      }
    } else {
      page = const NotifikasiLogScreen();
    }

    navigator.push(MaterialPageRoute(builder: (_) => page));
  }
}
