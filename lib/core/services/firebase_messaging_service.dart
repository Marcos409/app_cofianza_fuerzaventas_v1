import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService instance = FirebaseMessagingService._();
  FirebaseMessagingService._();

  bool _initialized = false;
  String? _currentToken;
  StreamSubscription? _tokenSubscription;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _currentToken = await messaging.getToken();
        _tokenSubscription = messaging.onTokenRefresh.listen((token) {
          _currentToken = token;
          _onTokenChanged(token);
        });
      }

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      _initialized = true;
    } catch (e) {
      debugPrint('FirebaseMessagingService: initialization skipped ($e)');
    }
  }

  String? get currentToken => _currentToken;

  void Function(String token)? onTokenChanged;
  void Function(Map<String, dynamic>? data)? onNotificationOpened;

  void _onTokenChanged(String token) {
    onTokenChanged?.call(token);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;
    final title = notification?.title ?? data['title'] ?? 'Notificación';
    final body = notification?.body ?? data['body'] ?? '';

    await NotificationService.instance.showGroupedNotification(
      id: data['solicitud_id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      groupKey: 'estado_solicitudes',
      title: title,
      body: body,
      summary: 'Cambios en tus solicitudes',
      payload: data['solicitud_id'],
    );
  }

  Future<void> _onNotificationOpened(RemoteMessage message) async {
    onNotificationOpened?.call(message.data);
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  final data = message.data;
  final title = notification?.title ?? data['title'] ?? 'Notificación';
  final body = notification?.body ?? data['body'] ?? '';

  await NotificationService.instance.showGroupedNotification(
    id: data['solicitud_id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    groupKey: 'estado_solicitudes',
    title: title,
    body: body,
    summary: 'Cambios en tus solicitudes',
    payload: data['solicitud_id'],
  );
}
