// lib/services/local_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'thix_id_high_importance';
  static const String _channelName = 'THIX ID Notifications';
  static const String _channelDescription = 'Notifications importantes de THIX ID';

  /// Callback appelé quand l'utilisateur tape sur une notification.
  void Function(String? payload)? onNotificationTap;

  /// Alias pour compatibilité
  Future<void> init() => initialize();

  Future<void> initialize() async {
    // 1. Protection Web : on évite d'exécuter du code natif sur navigateur
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 🌟 RETOUR DE TON ASTUCE WEB !
    // Le cast en 'dynamic' empêche le compilateur dart2js (GitHub Actions)
    // de crasher sur les signatures non conformes des stubs Web du package.
    await (_plugin as dynamic).initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // En dynamic, response peut être n'importe quoi, on utilise '?' par sécurité
        debugPrint('🔔 Clic notification -> payload: ${response?.payload}');
        onNotificationTap?.call(response?.payload);
      },
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    debugPrint('LocalNotificationService: initialisé');
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      debugPrint('🔔 [Web Notification] $title: $body');
      return;
    }

    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      // 🌟 On cast en dynamic ici aussi pour éviter le crash "Too many positional arguments" lors du build Web
      await (_plugin as dynamic).show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('LocalNotificationService: show failed err=$e');
    }
  }

  Future<void> cancel(int id) async {
    if (!kIsWeb) await (_plugin as dynamic).cancel(id);
  }

  Future<void> cancelAll() async {
    if (!kIsWeb) await (_plugin as dynamic).cancelAll();
  }
}
